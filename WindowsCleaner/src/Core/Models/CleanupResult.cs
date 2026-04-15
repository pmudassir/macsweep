namespace WinSweep.Core.Models;

/// <summary>
/// Summarises the outcome of a cleanup operation.
/// Windows equivalent of MacSweep's CleanupResult model.
/// </summary>
public sealed class CleanupResult
{
    /// <summary>Total number of files successfully removed.</summary>
    public int FilesRemoved { get; init; }

    /// <summary>Total bytes freed by the operation.</summary>
    public long SpaceFreed { get; init; }

    /// <summary>Any non-fatal errors that occurred during cleanup.</summary>
    public IReadOnlyList<string> Errors { get; init; } = [];

    /// <summary>Human-readable representation of the space freed.</summary>
    public string FormattedSpaceFreed => ScannedItem.FormatBytes(SpaceFreed);

    /// <summary>Whether any errors occurred during the operation.</summary>
    public bool HasErrors => Errors.Count > 0;
}
