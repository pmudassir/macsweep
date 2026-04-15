using System.ComponentModel;
using System.Runtime.CompilerServices;

namespace WinSweep.ViewModels;

/// <summary>
/// Minimal INotifyPropertyChanged base class.
/// No third-party dependencies — plain .NET 8 BCL only.
/// </summary>
public abstract class ObservableBase : INotifyPropertyChanged
{
    public event PropertyChangedEventHandler? PropertyChanged;

    /// <summary>Sets the backing field and raises PropertyChanged if the value changed.</summary>
    protected bool SetProperty<T>(ref T field, T value,
        [CallerMemberName] string? propertyName = null)
    {
        if (EqualityComparer<T>.Default.Equals(field, value)) return false;
        field = value;
        OnPropertyChanged(propertyName);
        return true;
    }

    protected void OnPropertyChanged([CallerMemberName] string? propertyName = null) =>
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
}
