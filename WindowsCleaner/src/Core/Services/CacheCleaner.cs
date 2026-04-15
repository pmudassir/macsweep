using System.Diagnostics;
using System.IO;
using WinSweep.Core.Models;

namespace WinSweep.Core.Services;

/// <summary>
/// Clears browser caches, Windows Update cache, thumbnail cache, DNS cache, and Prefetch.
/// Windows equivalent of MacSweep's browser + system cache clearing.
/// </summary>
public sealed class CacheCleaner
{
    private readonly SafetyValidator _validator = SafetyValidator.Shared;

    // ── Path helpers ──────────────────────────────────────────────────────────

    private static string LocalAppData =>
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);

    private static string WindowsDir =>
        Environment.GetFolderPath(Environment.SpecialFolder.Windows);

    private static string[] ChromeCachePaths =>
    [
        Path.Combine(LocalAppData, "Google", "Chrome", "User Data", "Default", "Cache"),
        Path.Combine(LocalAppData, "Google", "Chrome", "User Data", "Default", "Code Cache"),
        Path.Combine(LocalAppData, "Google", "Chrome", "User Data", "Default", "GPUCache"),
    ];

    private static string[] EdgeCachePaths =>
    [
        Path.Combine(LocalAppData, "Microsoft", "Edge", "User Data", "Default", "Cache"),
        Path.Combine(LocalAppData, "Microsoft", "Edge", "User Data", "Default", "Code Cache"),
        Path.Combine(LocalAppData, "Microsoft", "Edge", "User Data", "Default", "GPUCache"),
    ];

    private static string[] FirefoxCachePaths
    {
        get
        {
            string profilesRoot = Path.Combine(LocalAppData, "Mozilla", "Firefox", "Profiles");
            if (!Directory.Exists(profilesRoot)) return [];
            return Directory.GetDirectories(profilesRoot)
                            .Select(p => Path.Combine(p, "cache2"))
                            .Where(Directory.Exists)
                            .ToArray();
        }
    }

    private static string WindowsUpdateCachePath =>
        Path.Combine(WindowsDir, "SoftwareDistribution", "Download");

    private static string[] ThumbnailCachePaths
    {
        get
        {
            string explorer = Path.Combine(LocalAppData, "Microsoft", "Windows", "Explorer");
            if (!Directory.Exists(explorer)) return [];
            return Directory.GetFiles(explorer, "thumbcache_*.db");
        }
    }

    private static string PrefetchPath => Path.Combine(WindowsDir, "Prefetch");

    // ── Public API ────────────────────────────────────────────────────────────

    /// <summary>
    /// Returns the total bytes currently occupied by the given category.
    /// Safe to call without admin rights (inaccessible folders return 0).
    /// </summary>
    public async Task<long> GetSizeAsync(
        CleanCategory category,
        CancellationToken cancellationToken = default)
    {
        return await Task.Run(() =>
        {
            return category switch
            {
                CleanCategory.BrowserCaches =>
                    GetDirsSize(ChromeCachePaths.Concat(EdgeCachePaths).Concat(FirefoxCachePaths)),
                CleanCategory.WindowsUpdateCache => GetDirsSize([WindowsUpdateCachePath]),
                CleanCategory.ThumbnailCache     => ThumbnailCachePaths.Sum(GetFileSize),
                CleanCategory.Prefetch           => GetDirsSize([PrefetchPath]),
                CleanCategory.TempFiles          => GetDirsSize(
                    [Path.GetTempPath(), Path.Combine(LocalAppData, "Temp")]),
                _ => 0L
            };
        }, cancellationToken);
    }

    /// <summary>
    /// Cleans the specified category and returns a <see cref="CleanupResult"/>.
    /// </summary>
    public async Task<CleanupResult> CleanAsync(
        CleanCategory category,
        IProgress<string>? progress = null,
        CancellationToken cancellationToken = default)
    {
        return category switch
        {
            CleanCategory.BrowserCaches =>
                await CleanDirectoriesAsync(
                    [.. ChromeCachePaths, .. EdgeCachePaths, .. FirefoxCachePaths],
                    "BrowserCaches", progress, cancellationToken),

            CleanCategory.WindowsUpdateCache =>
                await CleanDirectoriesAsync(
                    [WindowsUpdateCachePath], "WindowsUpdateCache", progress, cancellationToken),

            CleanCategory.ThumbnailCache =>
                await CleanFilesAsync(
                    ThumbnailCachePaths, "ThumbnailCache", progress, cancellationToken),

            CleanCategory.Prefetch =>
                await CleanDirectoriesAsync(
                    [PrefetchPath], "Prefetch", progress, cancellationToken),

            CleanCategory.DnsCache => await FlushDnsAsync(progress),

            CleanCategory.TempFiles =>
                await CleanDirectoriesAsync(
                    [Path.GetTempPath(), Path.Combine(LocalAppData, "Temp")],
                    "TempFiles", progress, cancellationToken),

            _ => new CleanupResult { Errors = ["Unknown category."] }
        };
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    private async Task<CleanupResult> CleanDirectoriesAsync(
        string[] dirs, string label,
        IProgress<string>? progress, CancellationToken ct)
    {
        return await Task.Run(async () =>
        {
            int  removed = 0;
            long freed   = 0;
            var  errors  = new List<string>();

            foreach (string dir in dirs)
            {
                if (!Directory.Exists(dir)) continue;

                // Verify directory is in the allowed whitelist before touching anything
                if (!_validator.IsSafeToDelete(Path.Combine(dir, "_probe")))
                {
                    errors.Add($"Blocked by safety validator: {dir}");
                    continue;
                }

                IEnumerable<string> files;
                try
                {
                    files = Directory.EnumerateFiles(dir, "*", SearchOption.AllDirectories);
                }
                catch (UnauthorizedAccessException ex)
                {
                    errors.Add($"Access denied: {dir} — {ex.Message}");
                    continue;
                }

                foreach (string file in files)
                {
                    ct.ThrowIfCancellationRequested();
                    progress?.Report($"Deleting {Path.GetFileName(file)} …");
                    try
                    {
                        long size = GetFileSize(file);
                        File.Delete(file);
                        removed++;
                        freed += size;
                        await OperationLogger.LogAsync($"CacheCleaner.{label}", file);
                    }
                    catch (Exception ex)
                    {
                        errors.Add($"{Path.GetFileName(file)}: {ex.Message}");
                        await OperationLogger.LogAsync($"CacheCleaner.{label}",
                            $"{file} — {ex.Message}", success: false);
                    }
                }
            }

            return new CleanupResult { FilesRemoved = removed, SpaceFreed = freed, Errors = errors };
        }, ct);
    }

    private async Task<CleanupResult> CleanFilesAsync(
        string[] filePaths, string label,
        IProgress<string>? progress, CancellationToken ct)
    {
        return await Task.Run(async () =>
        {
            int  removed = 0;
            long freed   = 0;
            var  errors  = new List<string>();

            foreach (string file in filePaths)
            {
                ct.ThrowIfCancellationRequested();
                if (!File.Exists(file)) continue;
                progress?.Report($"Deleting {Path.GetFileName(file)} …");
                try
                {
                    long size = GetFileSize(file);
                    File.Delete(file);
                    removed++;
                    freed += size;
                    await OperationLogger.LogAsync($"CacheCleaner.{label}", file);
                }
                catch (Exception ex)
                {
                    errors.Add($"{Path.GetFileName(file)}: {ex.Message}");
                    await OperationLogger.LogAsync($"CacheCleaner.{label}",
                        $"{file} — {ex.Message}", success: false);
                }
            }

            return new CleanupResult { FilesRemoved = removed, SpaceFreed = freed, Errors = errors };
        }, ct);
    }

    private static async Task<CleanupResult> FlushDnsAsync(IProgress<string>? progress)
    {
        progress?.Report("Flushing DNS resolver cache …");
        try
        {
            var psi = new ProcessStartInfo("ipconfig", "/flushdns")
            {
                UseShellExecute        = false,
                RedirectStandardOutput = true,
                RedirectStandardError  = true,
                CreateNoWindow         = true
            };

            using var proc = Process.Start(psi)
                             ?? throw new InvalidOperationException("Cannot start ipconfig.");
            await proc.WaitForExitAsync().ConfigureAwait(false);
            await OperationLogger.LogAsync("CacheCleaner.DnsFlush", "ipconfig /flushdns");
            return new CleanupResult { FilesRemoved = 0, SpaceFreed = 0, Errors = [] };
        }
        catch (Exception ex)
        {
            await OperationLogger.LogAsync("CacheCleaner.DnsFlush", ex.Message, success: false);
            return new CleanupResult { Errors = [ex.Message] };
        }
    }

    private static long GetDirsSize(IEnumerable<string> paths)
    {
        long total = 0;
        foreach (string dir in paths)
        {
            if (!Directory.Exists(dir)) continue;
            try
            {
                foreach (string f in Directory.EnumerateFiles(dir, "*", SearchOption.AllDirectories))
                    total += GetFileSize(f);
            }
            catch { /* access denied — skip */ }
        }
        return total;
    }

    private static long GetFileSize(string path)
    {
        try   { return new FileInfo(path).Length; }
        catch { return 0L; }
    }
}
