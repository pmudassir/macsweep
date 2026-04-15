using System.Diagnostics;
using System.IO;
using System.Text;
using Microsoft.Win32;
using WinSweep.Core.Models;

namespace WinSweep.Core.Services;

/// <summary>
/// Reads and manages Windows startup items from:
///   • HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run
///   • HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run
///   • shell:startup  (per-user Startup folder)
///   • shell:common startup (all-users Startup folder)
///   • Task Scheduler (At logon triggers, via schtasks.exe)
///
/// Windows equivalent of macOS Login Items / LaunchAgents management.
/// </summary>
public sealed class StartupManager
{
    private readonly SafetyValidator _validator = SafetyValidator.Shared;

    private const string RunKeyPath      = @"SOFTWARE\Microsoft\Windows\CurrentVersion\Run";
    private const string ApprovedKeyPath =
        @"SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run";

    // ── Read all entries ──────────────────────────────────────────────────────

    /// <summary>
    /// Asynchronously reads all startup entries from all standard Windows locations.
    /// </summary>
    public async Task<IReadOnlyList<StartupEntry>> GetAllEntriesAsync()
    {
        var entries = new List<StartupEntry>();

        await Task.Run(() =>
        {
            entries.AddRange(ReadRegistryRunEntries(Registry.CurrentUser,
                StartupSource.HkcuRegistry));

            try
            {
                entries.AddRange(ReadRegistryRunEntries(Registry.LocalMachine,
                    StartupSource.HklmRegistry));
            }
            catch (UnauthorizedAccessException) { /* HKLM requires elevation */ }

            entries.AddRange(ReadStartupFolder(
                Environment.GetFolderPath(Environment.SpecialFolder.Startup),
                StartupSource.UserStartupFolder));

            try
            {
                entries.AddRange(ReadStartupFolder(
                    Environment.GetFolderPath(Environment.SpecialFolder.CommonStartup),
                    StartupSource.AllUsersStartupFolder));
            }
            catch (UnauthorizedAccessException) { /* May require elevation */ }
        });

        try
        {
            var sched = await ReadTaskSchedulerEntriesAsync().ConfigureAwait(false);
            entries.AddRange(sched);
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine(
                $"[StartupManager] Task Scheduler read failed: {ex.Message}");
        }

        return entries;
    }

    // ── Enable / Disable ─────────────────────────────────────────────────────

    /// <summary>Enables a startup entry that was previously disabled.</summary>
    public async Task EnableEntryAsync(StartupEntry entry)
    {
        await Task.Run(() =>
        {
            switch (entry.Source)
            {
                case StartupSource.HkcuRegistry:
                    SetStartupApproved(Registry.CurrentUser, entry.OriginalKey, enabled: true);
                    break;
                case StartupSource.HklmRegistry:
                    SetStartupApproved(Registry.LocalMachine, entry.OriginalKey, enabled: true);
                    break;
                case StartupSource.UserStartupFolder:
                case StartupSource.AllUsersStartupFolder:
                    EnableStartupFolderItem(entry);
                    break;
                case StartupSource.TaskScheduler:
                    RunSchtasks($"/change /tn \"{entry.OriginalKey}\" /enable");
                    break;
            }
        });

        entry.IsEnabled = true;
        await OperationLogger.LogAsync("StartupManager.Enable", entry.Name);
    }

    /// <summary>Disables a startup entry (does NOT delete it).</summary>
    public async Task DisableEntryAsync(StartupEntry entry)
    {
        if (entry.IsSystemCritical) return;

        await Task.Run(() =>
        {
            switch (entry.Source)
            {
                case StartupSource.HkcuRegistry:
                    SetStartupApproved(Registry.CurrentUser, entry.OriginalKey, enabled: false);
                    break;
                case StartupSource.HklmRegistry:
                    SetStartupApproved(Registry.LocalMachine, entry.OriginalKey, enabled: false);
                    break;
                case StartupSource.UserStartupFolder:
                case StartupSource.AllUsersStartupFolder:
                    DisableStartupFolderItem(entry);
                    break;
                case StartupSource.TaskScheduler:
                    RunSchtasks($"/change /tn \"{entry.OriginalKey}\" /disable");
                    break;
            }
        });

        entry.IsEnabled = false;
        await OperationLogger.LogAsync("StartupManager.Disable", entry.Name);
    }

    // ── Delete ────────────────────────────────────────────────────────────────

    /// <summary>
    /// Permanently deletes a startup entry.
    /// Always confirm with the user before calling this method.
    /// </summary>
    public async Task DeleteEntryAsync(StartupEntry entry)
    {
        if (entry.IsSystemCritical) return;

        await Task.Run(() =>
        {
            switch (entry.Source)
            {
                case StartupSource.HkcuRegistry:
                    DeleteRegistryValue(Registry.CurrentUser, entry.OriginalKey);
                    break;
                case StartupSource.HklmRegistry:
                    DeleteRegistryValue(Registry.LocalMachine, entry.OriginalKey);
                    break;
                case StartupSource.UserStartupFolder:
                case StartupSource.AllUsersStartupFolder:
                    if (File.Exists(entry.ExecutablePath))
                        File.Delete(entry.ExecutablePath);
                    break;
                case StartupSource.TaskScheduler:
                    RunSchtasks($"/delete /tn \"{entry.OriginalKey}\" /f");
                    break;
            }
        });

        await OperationLogger.LogAsync("StartupManager.Delete", entry.Name);
    }

    // ── Registry helpers ──────────────────────────────────────────────────────

    private IEnumerable<StartupEntry> ReadRegistryRunEntries(
        RegistryKey hive, StartupSource source)
    {
        var entries = new List<StartupEntry>();

        using RegistryKey? runKey = hive.OpenSubKey(RunKeyPath, writable: false);
        if (runKey == null) return entries;

        Dictionary<string, bool> approved = ReadApprovedStatus(hive);

        foreach (string name in runKey.GetValueNames())
        {
            string? value = runKey.GetValue(name)?.ToString();
            if (string.IsNullOrWhiteSpace(value)) continue;

            string exePath   = ExtractExePath(value);
            bool isCritical  = _validator.IsSystemCriticalStartup(name);
            bool isEnabled   = approved.GetValueOrDefault(name, defaultValue: true);

            entries.Add(new StartupEntry
            {
                Name             = name,
                Publisher        = GetFilePublisher(exePath),
                ExecutablePath   = exePath,
                Source           = source,
                IsEnabled        = isEnabled,
                IsSystemCritical = isCritical,
                OriginalKey      = name
            });
        }

        return entries;
    }

    private static Dictionary<string, bool> ReadApprovedStatus(RegistryKey hive)
    {
        var status = new Dictionary<string, bool>(StringComparer.OrdinalIgnoreCase);
        try
        {
            using RegistryKey? key = hive.OpenSubKey(ApprovedKeyPath, writable: false);
            if (key == null) return status;

            foreach (string name in key.GetValueNames())
            {
                byte[]? data = key.GetValue(name) as byte[];
                // First byte: 0x02 = enabled, 0x03 = disabled
                status[name] = data == null || data.Length == 0 || data[0] == 0x02;
            }
        }
        catch { /* Non-critical */ }
        return status;
    }

    private static void SetStartupApproved(RegistryKey hive, string valueName, bool enabled)
    {
        try
        {
            using RegistryKey key = hive.CreateSubKey(ApprovedKeyPath, writable: true);
            byte[] data = new byte[12];
            data[0] = enabled ? (byte)0x02 : (byte)0x03;
            key.SetValue(valueName, data, RegistryValueKind.Binary);
        }
        catch (UnauthorizedAccessException) { /* Requires elevation for HKLM */ }
    }

    private static void DeleteRegistryValue(RegistryKey hive, string valueName)
    {
        try
        {
            using RegistryKey? key = hive.OpenSubKey(RunKeyPath, writable: true);
            key?.DeleteValue(valueName, throwOnMissingValue: false);

            using RegistryKey? approvedKey = hive.OpenSubKey(ApprovedKeyPath, writable: true);
            approvedKey?.DeleteValue(valueName, throwOnMissingValue: false);
        }
        catch (UnauthorizedAccessException) { /* Requires elevation for HKLM */ }
    }

    // ── Startup folder helpers ────────────────────────────────────────────────

    private static IEnumerable<StartupEntry> ReadStartupFolder(
        string folderPath, StartupSource source)
    {
        var entries = new List<StartupEntry>();
        if (!Directory.Exists(folderPath)) return entries;

        foreach (string file in Directory.GetFiles(folderPath, "*.lnk"))
        {
            string name = Path.GetFileNameWithoutExtension(file);
            entries.Add(new StartupEntry
            {
                Name             = name,
                Publisher        = string.Empty,
                ExecutablePath   = file,
                Source           = source,
                IsEnabled        = true,
                IsSystemCritical = false,
                OriginalKey      = file
            });
        }

        return entries;
    }

    private static void EnableStartupFolderItem(StartupEntry entry)
    {
        string disabledDir  = Path.Combine(
            Path.GetDirectoryName(entry.ExecutablePath) ?? string.Empty,
            "_WinSweep_Disabled");
        string disabledPath = Path.Combine(disabledDir,
            Path.GetFileName(entry.ExecutablePath));

        if (File.Exists(disabledPath) && !File.Exists(entry.OriginalKey))
            File.Move(disabledPath, entry.OriginalKey);
    }

    private static void DisableStartupFolderItem(StartupEntry entry)
    {
        string disabledDir = Path.Combine(
            Path.GetDirectoryName(entry.ExecutablePath) ?? string.Empty,
            "_WinSweep_Disabled");
        Directory.CreateDirectory(disabledDir);

        string dest = Path.Combine(disabledDir, Path.GetFileName(entry.ExecutablePath));
        if (File.Exists(entry.ExecutablePath))
            File.Move(entry.ExecutablePath, dest, overwrite: true);
    }

    // ── Task Scheduler helpers ────────────────────────────────────────────────

    private static async Task<IEnumerable<StartupEntry>> ReadTaskSchedulerEntriesAsync()
    {
        var entries = new List<StartupEntry>();

        var psi = new ProcessStartInfo("schtasks", "/query /fo CSV /v")
        {
            UseShellExecute        = false,
            RedirectStandardOutput = true,
            RedirectStandardError  = true,
            CreateNoWindow         = true,
            StandardOutputEncoding = Encoding.UTF8
        };

        string output;
        using (var proc = Process.Start(psi)!)
        {
            output = await proc.StandardOutput.ReadToEndAsync().ConfigureAwait(false);
            await proc.WaitForExitAsync().ConfigureAwait(false);
        }

        string[] lines = output.Split('\n', StringSplitOptions.RemoveEmptyEntries);
        if (lines.Length < 2) return entries;

        // Skip the CSV header line (index 0)
        for (int i = 1; i < lines.Length; i++)
        {
            List<string> f = ParseCsvLine(lines[i]);
            if (f.Count < 19) continue;

            string taskName  = f[1].Trim('"');
            string schedType = f.Count > 18 ? f[18].Trim('"') : string.Empty;
            string state     = f.Count > 11 ? f[11].Trim('"') : string.Empty;
            string author    = f.Count > 7  ? f[7].Trim('"')  : string.Empty;
            string taskToRun = f.Count > 8  ? f[8].Trim('"')  : string.Empty;

            // Skip Microsoft built-in system tasks
            if (taskName.StartsWith(@"\Microsoft\", StringComparison.OrdinalIgnoreCase))
                continue;

            // Only surface tasks triggered at logon
            if (!schedType.Equals("At logon", StringComparison.OrdinalIgnoreCase))
                continue;

            entries.Add(new StartupEntry
            {
                Name             = Path.GetFileName(taskName.TrimStart('\\')),
                Publisher        = author,
                ExecutablePath   = taskToRun,
                Source           = StartupSource.TaskScheduler,
                IsEnabled        = state.Equals("Enabled", StringComparison.OrdinalIgnoreCase),
                IsSystemCritical = false,
                OriginalKey      = taskName
            });
        }

        return entries;
    }

    private static void RunSchtasks(string args)
    {
        var psi = new ProcessStartInfo("schtasks", args)
        {
            UseShellExecute        = false,
            RedirectStandardOutput = true,
            RedirectStandardError  = true,
            CreateNoWindow         = true
        };
        using var proc = Process.Start(psi);
        proc?.WaitForExit();
    }

    // ── Utility helpers ───────────────────────────────────────────────────────

    private static string ExtractExePath(string rawValue)
    {
        rawValue = rawValue.Trim();
        if (rawValue.StartsWith('"'))
        {
            int end = rawValue.IndexOf('"', 1);
            if (end > 0) return rawValue[1..end];
        }
        int space = rawValue.IndexOf(' ');
        return space > 0 ? rawValue[..space] : rawValue;
    }

    private static string GetFilePublisher(string exePath)
    {
        try
        {
            if (!File.Exists(exePath)) return string.Empty;
            var info = FileVersionInfo.GetVersionInfo(exePath);
            return !string.IsNullOrWhiteSpace(info.CompanyName)
                ? info.CompanyName
                : info.FileDescription ?? string.Empty;
        }
        catch { return string.Empty; }
    }

    private static List<string> ParseCsvLine(string line)
    {
        var fields  = new List<string>();
        var current = new StringBuilder();
        bool inQuotes = false;

        foreach (char ch in line)
        {
            if      (ch == '"')              inQuotes = !inQuotes;
            else if (ch == ',' && !inQuotes) { fields.Add(current.ToString()); current.Clear(); }
            else                             current.Append(ch);
        }

        fields.Add(current.ToString());
        return fields;
    }
}
