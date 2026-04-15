using System.IO;

namespace WinSweep.Core.Services;

/// <summary>
/// Writes a timestamped audit trail of every destructive operation to
/// %LOCALAPPDATA%\WinSweep\Logs\cleaner.log.
/// Thread-safe via an async semaphore.
/// </summary>
public static class OperationLogger
{
    private static readonly string LogDirectory = System.IO.Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "WinSweep", "Logs");

    private static readonly string LogFile =
        System.IO.Path.Combine(LogDirectory, "cleaner.log");

    private static readonly SemaphoreSlim WriteLock = new(1, 1);

    /// <summary>Full path to the active log file.</summary>
    public static string LogFilePath => LogFile;

    /// <summary>
    /// Appends a single log line asynchronously. Never throws — swallows I/O errors.
    /// </summary>
    /// <param name="operation">Short operation name, e.g. "JunkCleaner.Delete".</param>
    /// <param name="detail">File path, registry key, etc.</param>
    /// <param name="success">False emits an ERR tag; true emits OK.</param>
    public static async Task LogAsync(string operation, string detail, bool success = true)
    {
        string tag  = success ? "OK " : "ERR";
        string line = $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] [{tag}] {operation}: {detail}";

        await WriteLock.WaitAsync().ConfigureAwait(false);
        try
        {
            Directory.CreateDirectory(LogDirectory);
            await File.AppendAllTextAsync(LogFile, line + Environment.NewLine)
                      .ConfigureAwait(false);
        }
        catch (Exception ex)
        {
            // Logging must never crash the application.
            System.Diagnostics.Debug.WriteLine($"[OperationLogger] {ex.Message}");
        }
        finally
        {
            WriteLock.Release();
        }
    }
}
