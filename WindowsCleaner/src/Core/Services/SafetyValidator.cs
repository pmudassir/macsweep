using System.IO;

namespace WinSweep.Core.Services;

/// <summary>
/// Prevents deletion of system-critical files and registry entries.
/// Windows equivalent of MacSweep's SafetyValidator.
/// </summary>
public sealed class SafetyValidator
{
    /// <summary>Singleton instance.</summary>
    public static readonly SafetyValidator Shared = new();

    private SafetyValidator() { }

    // ── Protected root paths that should never be deleted ────────────────────

    private static readonly string[] ProtectedRoots = BuildProtectedRoots();

    private static string[] BuildProtectedRoots()
    {
        var roots = new List<string>
        {
            Environment.GetFolderPath(Environment.SpecialFolder.Windows),
            Environment.GetFolderPath(Environment.SpecialFolder.System),
            Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles),
        };

        string x86 = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86);
        if (!string.IsNullOrEmpty(x86)) roots.Add(x86);

        roots.Add(Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.Windows), "SysWOW64"));

        string pd = Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData);
        if (!string.IsNullOrEmpty(pd)) roots.Add(pd);

        return [.. roots];
    }

    // ── Whitelisted sub-paths inside protected roots ──────────────────────────

    private static readonly string[] AllowedSubPaths = BuildAllowedSubPaths();

    private static string[] BuildAllowedSubPaths()
    {
        string local   = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
        string windows = Environment.GetFolderPath(Environment.SpecialFolder.Windows);
        string temp    = Path.GetTempPath();

        return
        [
            Path.Combine(local, "Temp"),
            temp,
            Path.Combine(windows, "SoftwareDistribution", "Download"),
            Path.Combine(windows, "Prefetch"),
            Path.Combine(local, "Microsoft", "Windows", "Explorer"),   // Thumbnail cache
            Path.Combine(local, "Google",    "Chrome",  "User Data"),
            Path.Combine(local, "Microsoft", "Edge",    "User Data"),
            Path.Combine(local, "Mozilla",   "Firefox", "Profiles"),
        ];
    }

    // ── System-critical startup names (must never be removed or disabled) ─────

    private static readonly HashSet<string> CriticalStartupNames =
        new(StringComparer.OrdinalIgnoreCase)
        {
            "SecurityHealth", "Windows Defender", "WindowsDefender",
            "WinDefend", "MsMpEng", "wuauclt", "Windows Update",
            "SgrmBroker", "sppsvc"
        };

    // ── Public API ─────────────────────────────────────────────────────────────

    /// <summary>
    /// Returns <c>true</c> when it is safe to delete the specified file or directory.
    /// </summary>
    public bool IsSafeToDelete(string path)
    {
        if (string.IsNullOrWhiteSpace(path)) return false;

        string full;
        try { full = Path.GetFullPath(path); }
        catch { return false; }

        foreach (string root in ProtectedRoots)
        {
            if (string.IsNullOrEmpty(root)) continue;

            bool isRoot  = full.Equals(root, StringComparison.OrdinalIgnoreCase);
            bool isChild = full.StartsWith(root + Path.DirectorySeparatorChar,
                                           StringComparison.OrdinalIgnoreCase);
            if (isRoot)  return false;
            if (isChild) return IsAllowedSubPath(full);
        }

        return true;
    }

    /// <summary>Returns <c>true</c> when the startup entry name is system-critical.</summary>
    public bool IsSystemCriticalStartup(string name) =>
        CriticalStartupNames.Contains(name);

    private static bool IsAllowedSubPath(string fullPath)
    {
        foreach (string allowed in AllowedSubPaths)
            if (fullPath.StartsWith(allowed, StringComparison.OrdinalIgnoreCase))
                return true;
        return false;
    }
}
