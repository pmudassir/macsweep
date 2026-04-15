using System.IO;
using WinSweep.Core.Models;

namespace WinSweep.Core.Services;

/// <summary>
/// Scans and cleans junk / temp files from standard Windows temp directories.
/// Windows equivalent of MacSweep's CleanupService targeting /tmp and ~/Library/Caches.
/// Mac paths  → Windows equivalents:
///   /tmp/              → %TEMP%  and  %LOCALAPPDATA%\Temp
///   ~/Library/Caches/  → %LOCALAPPDATA%\ (app cache sub-folders)
/// </summary>
public sealed class JunkCleaner
{
    private readonly SafetyValidator _validator = SafetyValidator.Shared;

    private static IEnumerable<string> ScanRoots =>
    [
        Path.GetTempPath(),
        Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Temp"),
    ];

    // ── Scan ──────────────────────────────────────────────────────────────────

    /// <summary>
    /// Enumerates temp files across all Windows temp directories.
    /// Returns one <see cref="ScannedItem"/> per file found.
    /// </summary>
    public async Task<IReadOnlyList<ScannedItem>> ScanAsync(
        IProgress<string>? progress = null,
        CancellationToken cancellationToken = default)
    {
        return await Task.Run(() =>
        {
            var results = new List<ScannedItem>();
            var seen    = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

            foreach (string root in ScanRoots)
            {
                if (!Directory.Exists(root)) continue;
                progress?.Report($"Scanning {root} …");

                IEnumerable<string> files;
                try
                {
                    files = Directory.EnumerateFiles(root, "*", SearchOption.AllDirectories);
                }
                catch (UnauthorizedAccessException) { continue; }
                catch (IOException)                 { continue; }

                foreach (string file in files)
                {
                    cancellationToken.ThrowIfCancellationRequested();
                    if (!seen.Add(file)) continue;

                    long size = 0;
                    try { size = new FileInfo(file).Length; }
                    catch { /* locked — record as 0 */ }

                    results.Add(new ScannedItem
                    {
                        Path           = file,
                        SizeBytes      = size,
                        Category       = "Temp Files",
                        IsSafeToDelete = _validator.IsSafeToDelete(file),
                        IsSelected     = true
                    });
                }
            }

            return (IReadOnlyList<ScannedItem>)results;
        }, cancellationToken);
    }

    // ── Clean ─────────────────────────────────────────────────────────────────

    /// <summary>
    /// Permanently deletes the supplied items after safety validation.
    /// Every deletion is logged to cleaner.log.
    /// Always ask the user to confirm before calling this method.
    /// </summary>
    public async Task<CleanupResult> CleanAsync(
        IEnumerable<ScannedItem> items,
        IProgress<string>? progress = null,
        CancellationToken cancellationToken = default)
    {
        return await Task.Run(async () =>
        {
            int    removed = 0;
            long   freed   = 0;
            var    errors  = new List<string>();

            foreach (ScannedItem item in items)
            {
                cancellationToken.ThrowIfCancellationRequested();

                if (!item.IsSafeToDelete || !_validator.IsSafeToDelete(item.Path))
                {
                    errors.Add($"Skipped (safety): {item.Path}");
                    await OperationLogger.LogAsync("JunkCleaner.Skip", item.Path, success: false);
                    continue;
                }

                progress?.Report($"Deleting {Path.GetFileName(item.Path)} …");

                try
                {
                    if (!File.Exists(item.Path)) continue;

                    long sizeOnDisk = new FileInfo(item.Path).Length;
                    File.Delete(item.Path);
                    removed++;
                    freed += sizeOnDisk;
                    await OperationLogger.LogAsync("JunkCleaner.Delete", item.Path);
                }
                catch (Exception ex)
                {
                    errors.Add($"{item.Path}: {ex.Message}");
                    await OperationLogger.LogAsync("JunkCleaner.Delete",
                        $"{item.Path} — {ex.Message}", success: false);
                }
            }

            return new CleanupResult
            {
                FilesRemoved = removed,
                SpaceFreed   = freed,
                Errors       = errors
            };
        }, cancellationToken);
    }
}
