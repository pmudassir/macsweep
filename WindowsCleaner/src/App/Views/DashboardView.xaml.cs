using System.Windows.Controls;
using WinSweep.ViewModels;

namespace WinSweep.Views;

/// <summary>Code-behind for DashboardView.xaml.</summary>
public partial class DashboardView : UserControl
{
    public DashboardView()
    {
        InitializeComponent();
        DataContext = new DashboardViewModel();
    }
}
