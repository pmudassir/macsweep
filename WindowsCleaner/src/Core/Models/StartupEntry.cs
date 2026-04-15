namespace WinSweep.Core.Models;

/// <summary>Identifies which location a startup entry was read from.</summary>
public enum StartupSource
{
    HkcuRegistry,
    HklmRegistry,
    UserStartupFolder,
    AllUsersStartupFolder,
    TaskScheduler
}

/// <summary>
/// Represents a single startup / login item discovered on the Windows system.
/// Windows equivalent of macOS LaunchAgents / Login Items.
/// </summary>
public sealed class StartupEntry
{
    /// <summary>Display name of the startup program.</summary>
    public string Name { get; init; } = string.Empty;

    /// <summary>Publisher / author (from file version metadata or registry).</summary>
    public string Publisher { get; init; } = string.Empty;

    /// <summary>Full path to the executable or .lnk target.</summary>
    public string ExecutablePath { get; init; } = string.Empty;

    /// <summary>The registry key, folder, or scheduler that hosts this entry.</summary>
    public StartupSource Source { get; init; }

    /// <summary>Whether the entry is currently enabled.</summary>
    public bool IsEnabled { get; set; }

    /// <summary>
    /// True for Windows Defender, WMI, etc. — these must never be removed.
    /// </summary>
    public bool IsSystemCritical { get; init; }

    /// <summary>
    /// The original registry value name or .lnk file path used for mutating operations.
    /// </summary>
    public string OriginalKey { get; init; } = string.Empty;

    /// <summary>Human-readable label for the source location.</summary>
    public string SourceDisplayName => Source switch
    {
        StartupSource.HkcuRegistry          => "HKCU Registry",
        StartupSource.HklmRegistry          => "HKLM Registry",
        StartupSource.UserStartupFolder     => "Startup Folder (User)",
        StartupSource.AllUsersStartupFolder => "Startup Folder (All Users)",
        StartupSource.TaskScheduler         => "Task Scheduler",
        _                                   => "Unknown"
    };
}
