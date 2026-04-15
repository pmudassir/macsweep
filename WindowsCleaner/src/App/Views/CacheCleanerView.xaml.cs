using System.Windows.Controls;
using WinSweep.ViewModels;

namespace WinSweep.Views;

/// <summary>Code-behind for CacheCleanerView.xaml.</summary>
public partial class CacheCleanerView : UserControl
{
    public CacheCleanerView()
    {
        InitializeComponent();
        DataContext = new CacheCleanerViewModel();
    }
}
