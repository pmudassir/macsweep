using System.Diagnostics;
using System.IO;
using System.Windows;
using System.Windows.Controls;
using WinSweep.Core.Services;

namespace WinSweep.Views;

/// <summary>Application shell window — hosts the sidebar and navigates between pages.</summary>
public partial class MainWindow : Window
{
    // Lazily-created page instances (reuse to preserve state)
    private DashboardView?      _dashboard;
    private JunkCleanerView?    _junkCleaner;
    private CacheCleanerView?   _cacheCleaner;
    private StartupManagerView? _startupManager;

    public MainWindow()
    {
        InitializeComponent();
        Show(GetOrCreate(ref _dashboard, () => new DashboardView()));
    }

    // ── Navigation handlers ───────────────────────────────────────────────

    private void NavDashboard_Checked(object sender, RoutedEventArgs e) =>
        Show(GetOrCreate(ref _dashboard, () => new DashboardView()));

    private void NavJunk_Checked(object sender, RoutedEventArgs e) =>
        Show(GetOrCreate(ref _junkCleaner, () => new JunkCleanerView()));

    private void NavCache_Checked(object sender, RoutedEventArgs e) =>
        Show(GetOrCreate(ref _cacheCleaner, () => new CacheCleanerView()));

    private void NavStartup_Checked(object sender, RoutedEventArgs e) =>
        Show(GetOrCreate(ref _startupManager, () => new StartupManagerView()));

    private void Show(UserControl page)
    {
        // Guard: NavDashboard_Checked fires during InitializeComponent() before
        // MainContent (column 2 ContentControl) has been instantiated by the parser.
        if (MainContent is null) return;
        MainContent.Content = page;
    }

    private static T GetOrCreate<T>(ref T? field, Func<T> factory) where T : class =>
        field ??= factory();

    // ── Log viewer ────────────────────────────────────────────────────────

    private void BtnOpenLog_Click(object sender, RoutedEventArgs e)
    {
        string logPath = OperationLogger.LogFilePath;
        if (File.Exists(logPath))
            Process.Start(new ProcessStartInfo(logPath) { UseShellExecute = true });
        else
            MessageBox.Show(
                "No log file yet. Perform a cleaning operation first.\n\nLog path:\n" + logPath,
                "WinSweep – Log File",
                MessageBoxButton.OK,
                MessageBoxImage.Information);
    }
}
