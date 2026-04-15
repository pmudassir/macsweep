using System.IO;
using WinSweep.Core.Models;

namespace WinSweep.ViewModels;

/// <summary>View model for the Dashboard overview page.</summary>
public sealed class DashboardViewModel : ObservableBase
{
    private string _diskFreeSpace          = "—";
    private string _diskTotalSpace         = "—";
    private string _diskUsedDisplay        = "—";
    private double _diskUsedPercent        = 0;
    private string _diskUsedPercentDisplay = "—";

    public string DiskFreeSpace
    {
        get => _diskFreeSpace;
        set => SetProperty(ref _diskFreeSpace, value);
    }

    public string DiskTotalSpace
    {
        get => _diskTotalSpace;
        set => SetProperty(ref _diskTotalSpace, value);
    }

    public string DiskUsedDisplay
    {
        get => _diskUsedDisplay;
        set => SetProperty(ref _diskUsedDisplay, value);
    }

    public double DiskUsedPercent
    {
        get => _diskUsedPercent;
        set => SetProperty(ref _diskUsedPercent, value);
    }

    public string DiskUsedPercentDisplay
    {
        get => _diskUsedPercentDisplay;
        set => SetProperty(ref _diskUsedPercentDisplay, value);
    }

    public DashboardViewModel() => LoadDiskInfo();

    private void LoadDiskInfo()
    {
        try
        {
            string root = Path.GetPathRoot(
                Environment.GetFolderPath(Environment.SpecialFolder.System)) ?? "C:\\";
            var drive = new DriveInfo(root);
            long free  = drive.AvailableFreeSpace;
            long total = drive.TotalSize;
            long used  = total - free;
            double pct = total > 0 ? used / (double)total * 100.0 : 0;

            DiskFreeSpace          = ScannedItem.FormatBytes(free);
            DiskTotalSpace         = ScannedItem.FormatBytes(total);
            DiskUsedDisplay        = ScannedItem.FormatBytes(used);
            DiskUsedPercent        = pct;
            DiskUsedPercentDisplay = $"{pct:F0}%";
        }
        catch
        {
            DiskFreeSpace  = "Unavailable";
            DiskTotalSpace = "Unavailable";
        }
    }
}
