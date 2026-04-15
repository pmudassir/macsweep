using System.Collections.ObjectModel;
using System.Windows;
using WinSweep.Core.Models;
using WinSweep.Core.Services;

namespace WinSweep.ViewModels;

/// <summary>View model for the Startup Manager page.</summary>
public sealed class StartupManagerViewModel : ObservableBase
{
    private readonly StartupManager _service = new();

    public ObservableCollection<StartupEntry> Entries { get; } = [];

    private bool   _isLoading  = false;
    private string _statusText = "Click Refresh to load startup items.";

    public bool IsLoading
    {
        get => _isLoading;
        set => SetProperty(ref _isLoading, value);
    }

    public string StatusText
    {
        get => _statusText;
        set => SetProperty(ref _statusText, value);
    }

    public AsyncRelayCommand              RefreshCommand { get; }
    public AsyncRelayCommand<StartupEntry> ToggleCommand { get; }
    public AsyncRelayCommand<StartupEntry> DeleteCommand  { get; }

    public StartupManagerViewModel()
    {
        RefreshCommand = new AsyncRelayCommand(LoadEntriesAsync);
        ToggleCommand  = new AsyncRelayCommand<StartupEntry>(ToggleEntryAsync);
        DeleteCommand  = new AsyncRelayCommand<StartupEntry>(DeleteEntryAsync);
    }

    // ── Load ──────────────────────────────────────────────────────────────────

    private async Task LoadEntriesAsync()
    {
        IsLoading  = true;
        StatusText = "Loading startup entries…";
        Entries.Clear();

        try
        {
            var all = await _service.GetAllEntriesAsync();
            foreach (var entry in all.OrderBy(e => e.Name))
                Entries.Add(entry);

            StatusText = $"Found {Entries.Count} startup item(s).";
        }
        catch (Exception ex)
        {
            StatusText = $"Error: {ex.Message}";
        }
        finally
        {
            IsLoading = false;
        }
    }

    // ── Toggle ────────────────────────────────────────────────────────────────

    private async Task ToggleEntryAsync(StartupEntry? entry)
    {
        if (entry == null || entry.IsSystemCritical) return;

        try
        {
            if (entry.IsEnabled)
                await _service.DisableEntryAsync(entry);
            else
                await _service.EnableEntryAsync(entry);

            // Force the collection to refresh this item
            int idx = Entries.IndexOf(entry);
            if (idx >= 0) { Entries.RemoveAt(idx); Entries.Insert(idx, entry); }

            StatusText = $"{entry.Name}: {(entry.IsEnabled ? "Enabled" : "Disabled")}.";
        }
        catch (Exception ex)
        {
            StatusText = $"Toggle failed: {ex.Message}";
        }
    }

    // ── Delete ────────────────────────────────────────────────────────────────

    private async Task DeleteEntryAsync(StartupEntry? entry)
    {
        if (entry == null || entry.IsSystemCritical) return;

        var confirm = MessageBox.Show(
            $"Delete startup entry '{entry.Name}'?\n\nThis cannot be undone.",
            "WinSweep – Confirm Delete",
            MessageBoxButton.YesNo,
            MessageBoxImage.Warning);

        if (confirm != MessageBoxResult.Yes) return;

        try
        {
            await _service.DeleteEntryAsync(entry);
            Entries.Remove(entry);
            StatusText = $"'{entry.Name}' removed from startup.";
        }
        catch (Exception ex)
        {
            StatusText = $"Delete failed: {ex.Message}";
        }
    }
}
