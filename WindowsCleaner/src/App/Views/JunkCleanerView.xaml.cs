using System.Windows;
using System.Windows.Controls;
using WinSweep.Core.Models;
using WinSweep.ViewModels;

namespace WinSweep.Views;

/// <summary>Code-behind for JunkCleanerView.xaml.</summary>
public partial class JunkCleanerView : UserControl
{
    private JunkCleanerViewModel _vm = null!;

    public JunkCleanerView()
    {
        InitializeComponent();
        _vm = new JunkCleanerViewModel();
        DataContext = _vm;
    }

    /// <summary>
    /// Updates the total selection stats whenever a checkbox is toggled directly in the list.
    /// </summary>
    private void FileCheckBox_Click(object sender, RoutedEventArgs e) =>
        _vm.UpdateSelectionStats();
}
