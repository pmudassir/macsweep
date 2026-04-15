namespace WinSweep.Core.Models;

/// <summary>
/// Enumeration of cache / junk categories that WinSweep can scan and clean.
/// Windows equivalent of MacSweep's ScanCategory enum.
/// </summary>
public enum CleanCategory
{
    /// <summary>%TEMP% and %LOCALAPPDATA%\Temp directories.</summary>
    TempFiles,

    /// <summary>User application cache folders under %LOCALAPPDATA%.</summary>
    UserCaches,

    /// <summary>Chrome, Edge, and Firefox cache directories.</summary>
    BrowserCaches,

    /// <summary>C:\Windows\SoftwareDistribution\Download (requires elevation).</summary>
    WindowsUpdateCache,

    /// <summary>Windows Explorer thumbnail cache files.</summary>
    ThumbnailCache,

    /// <summary>DNS resolver cache (flushed via ipconfig /flushdns).</summary>
    DnsCache,

    /// <summary>C:\Windows\Prefetch (requires elevation, optional).</summary>
    Prefetch
}
