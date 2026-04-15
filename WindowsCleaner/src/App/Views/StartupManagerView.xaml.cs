using System.Windows;
using System.Windows.Controls;
using WinSweep.Core.Models;
using WinSweep.ViewModels;

namespace WinSweep.Views;

/// <summary>Code-behind for StartupManagerView.xaml.</summary>
public partial class StartupManagerView : UserControl
{
    private StartupManagerViewModel _vm = null!;

    public StartupManagerView()
    {
        InitializeComponent();
        _vm = new StartupManagerViewModel();
        DataContext = _vm;
    }

    /// <summary>
    /// Fires the ToggleCommand with the StartupEntry stored in the button's Tag.
    /// Using code-behind because XAML CommandParameter binding inside DataTemplate
    /// requires RelativeSource gymnastics that create more complexity than a small handler.
    /// </summary>
    private void Toggle_Click(object sender, RoutedEventArgs e)
    {
        if (sender is CheckBox { Tag: StartupEntry entry })
            _vm.ToggleCommand.Execute(entry);
    }

    /// <summary>Fires the DeleteCommand with the StartupEntry stored in the button's Tag.</summary>
    private void Delete_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button { Tag: StartupEntry entry })
            _vm.DeleteCommand.Execute(entry);
    }
}
