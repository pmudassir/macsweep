using System.IO;

namespace WinSweep.Core.Models;

/// <summary>
/// Represents a single file discovered during a junk / temp scan.
/// Windows equivalent of MacSweep's ScannedFile model.
/// </summary>
public sealed class ScannedItem
{
    /// <summary>Full absolute path to the file on disk.</summary>
    public string Path { get; init; } = string.Empty;

    /// <summary>File size in bytes at time of scan.</summary>
    public long SizeBytes { get; init; }

    /// <summary>Display category (e.g., "Temp Files", "Browser Cache").</summary>
    public string Category { get; init; } = string.Empty;

    /// <summary>Whether the safety validator cleared this file for deletion.</summary>
    public bool IsSafeToDelete { get; init; }

    /// <summary>Whether this item is currently selected by the user for deletion.</summary>
    public bool IsSelected { get; set; } = true;

    /// <summary>File name only (no directory portion).</summary>
    public string DisplayName => System.IO.Path.GetFileName(Path);

    /// <summary>Human-readable file size string (e.g., "12.3 MB").</summary>
    public string FormattedSize => FormatBytes(SizeBytes);

    /// <summary>Converts a byte count to a human-readable string.</summary>
    public static string FormatBytes(long bytes)
    {
        if (bytes >= 1_073_741_824L) return $"{bytes / 1_073_741_824.0:F1} GB";
        if (bytes >= 1_048_576L)    return $"{bytes / 1_048_576.0:F1} MB";
        if (bytes >= 1_024L)        return $"{bytes / 1_024.0:F1} KB";
        return $"{bytes} B";
    }
}
