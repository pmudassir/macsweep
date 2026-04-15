using System.Text;
using System.Windows;
using System.Windows.Threading;

namespace WinSweep;

/// <summary>Application entry point. Handles unhandled UI-thread exceptions.</summary>
public partial class App : Application
{
    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);
        DispatcherUnhandledException += OnDispatcherUnhandledException;
        AppDomain.CurrentDomain.UnhandledException += OnUnhandledException;
    }

    private static void OnDispatcherUnhandledException(
        object sender, DispatcherUnhandledExceptionEventArgs e)
    {
        ShowError(e.Exception);
        e.Handled = true;
    }

    private static void OnUnhandledException(object sender, UnhandledExceptionEventArgs e) =>
        ShowError(e.ExceptionObject as Exception);

    /// <summary>
    /// Walks the full InnerException chain and displays all messages + types.
    /// This reveals the real cause hidden behind TargetInvocationException.
    /// </summary>
    private static void ShowError(Exception? ex)
    {
        var sb = new StringBuilder();
        sb.AppendLine("WinSweep encountered an error at startup.");
        sb.AppendLine();

        Exception? current = ex;
        int depth = 0;
        while (current != null && depth < 10)
        {
            sb.AppendLine($"[{depth}] {current.GetType().Name}");
            sb.AppendLine($"    {current.Message}");
            if (current.StackTrace is { } st)
            {
                // Show only the first 3 stack frames to keep the dialog readable
                string[] lines = st.Split('\n');
                foreach (string line in lines.Take(3))
                    sb.AppendLine("    " + line.Trim());
            }
            sb.AppendLine();
            current = current.InnerException;
            depth++;
        }

        MessageBox.Show(sb.ToString(),
            "WinSweep – Startup Error",
            MessageBoxButton.OK,
            MessageBoxImage.Error);
    }
}
