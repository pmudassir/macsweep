using System.Collections.ObjectModel;
using System.Windows;
using WinSweep.Core.Models;
using WinSweep.Core.Services;

namespace WinSweep.ViewModels;

/// <summary>View model for the Junk / Temp File Cleaner page.</summary>
public sealed class JunkCleanerViewModel : ObservableBase
{
    private readonly JunkCleaner _service = new();
    private CancellationTokenSource _cts = new();

    // ── Observable state ─────────────────────────────────────────────────────

    private bool   _isScanning    = false;
    private bool   _isCleaning    = false;
    private string _statusText    = "Ready. Click Scan to find junk files.";
    private string _selectedSize  = "0 B";
    private int    _selectedCount = 0;

    public ObservableCollection<ScannedItem> Items { get; } = [];

    public bool IsScanning
    {
        get => _isScanning;
        set
        {
            SetProperty(ref _isScanning, value);
            OnPropertyChanged(nameof(IsBusy));
            OnPropertyChanged(nameof(CanScan));
            OnPropertyChanged(nameof(CanClean));
        }
    }

    public bool IsCleaning
    {
        get => _isCleaning;
        set
        {
            SetProperty(ref _isCleaning, value);
            OnPropertyChanged(nameof(IsBusy));
            OnPropertyChanged(nameof(CanScan));
            OnPropertyChanged(nameof(CanClean));
        }
    }

    public bool IsBusy   => IsScanning || IsCleaning;
    public bool CanScan  => !IsBusy;
    public bool CanClean => !IsBusy && Items.Count > 0;

    public string StatusText
    {
        get => _statusText;
        set => SetProperty(ref _statusText, value);
    }

    public string SelectedSize
    {
        get => _selectedSize;
        set => SetProperty(ref _selectedSize, value);
    }

    public int SelectedCount
    {
        get => _selectedCount;
        set => SetProperty(ref _selectedCount, value);
    }

    // ── Commands ──────────────────────────────────────────────────────────────

    public AsyncRelayCommand ScanCommand       { get; }
    public AsyncRelayCommand CleanCommand      { get; }
    public RelayCommand      SelectAllCommand  { get; }
    public RelayCommand      DeselectAllCommand { get; }

    public JunkCleanerViewModel()
    {
        ScanCommand        = new AsyncRelayCommand(ScanAsync,   () => CanScan);
        CleanCommand       = new AsyncRelayCommand(CleanAsync,  () => CanClean);
        SelectAllCommand   = new RelayCommand(SelectAll);
        DeselectAllCommand = new RelayCommand(DeselectAll);
    }

    // ── Scan ──────────────────────────────────────────────────────────────────

    private async Task ScanAsync()
    {
        _cts       = new CancellationTokenSource();
        IsScanning = true;
        Items.Clear();
        StatusText = "Scanning temp directories…";

        try
        {
            var progress = new Progress<string>(msg => StatusText = msg);
            var found    = await _service.ScanAsync(progress, _cts.Token);

            foreach (var item in found)
                Items.Add(item);

            UpdateSelectionStats();
            StatusText = $"Found {Items.Count:N0} files  ({SelectedSize} selected).";
        }
        catch (OperationCanceledException)
        {
            StatusText = "Scan cancelled.";
        }
        catch (Exception ex)
        {
            StatusText = $"Scan error: {ex.Message}";
        }
        finally
        {
            IsScanning = false;
        }
    }

    // ── Clean ─────────────────────────────────────────────────────────────────

    private async Task CleanAsync()
    {
        var selected = Items.Where(i => i.IsSelected && i.IsSafeToDelete).ToList();
        if (selected.Count == 0) { StatusText = "No safe files selected."; return; }

        var confirm = MessageBox.Show(
            $"Permanently delete {selected.Count:N0} files " +
            $"({ScannedItem.FormatBytes(selected.Sum(i => i.SizeBytes))})?\n\nThis cannot be undone.",
            "WinSweep – Confirm Deletion",
            MessageBoxButton.YesNo,
            MessageBoxImage.Warning);

        if (confirm != MessageBoxResult.Yes) return;

        _cts       = new CancellationTokenSource();
        IsCleaning = true;
        StatusText  = "Cleaning…";

        try
        {
            var progress = new Progress<string>(msg => StatusText = msg);
            var result   = await _service.CleanAsync(selected, progress, _cts.Token);

            foreach (var item in selected)
                Items.Remove(item);

            UpdateSelectionStats();
            StatusText = $"Done. Freed {result.FormattedSpaceFreed} " +
                         $"({result.FilesRemoved:N0} files removed).";

            if (result.HasErrors)
                StatusText += $"  ({result.Errors.Count} skipped — see log.)";
        }
        catch (OperationCanceledException)
        {
            StatusText = "Cleaning cancelled.";
        }
        catch (Exception ex)
        {
            StatusText = $"Clean error: {ex.Message}";
        }
        finally
        {
            IsCleaning = false;
        }
    }

    // ── Selection helpers ─────────────────────────────────────────────────────

    private void SelectAll()
    {
        foreach (var item in Items) item.IsSelected = true;
        UpdateSelectionStats();
    }

    private void DeselectAll()
    {
        foreach (var item in Items) item.IsSelected = false;
        UpdateSelectionStats();
    }

    public void UpdateSelectionStats()
    {
        var sel       = Items.Where(i => i.IsSelected && i.IsSafeToDelete).ToList();
        SelectedCount = sel.Count;
        SelectedSize  = ScannedItem.FormatBytes(sel.Sum(x => x.SizeBytes));
        OnPropertyChanged(nameof(CanClean));
    }
}
