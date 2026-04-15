using System.Collections.ObjectModel;
using System.Windows;
using WinSweep.Core.Models;
using WinSweep.Core.Services;

namespace WinSweep.ViewModels;

/// <summary>View model for the Cache Cleaner page.</summary>
public sealed class CacheCleanerViewModel : ObservableBase
{
    private readonly CacheCleaner _service = new();

    public ObservableCollection<CacheCardViewModel> Cards { get; } = [];

    private string _statusText = "Click 'Scan All' to measure cache sizes.";
    public string StatusText
    {
        get => _statusText;
        set => SetProperty(ref _statusText, value);
    }

    public AsyncRelayCommand ScanAllCommand  { get; }
    public AsyncRelayCommand CleanAllCommand { get; }

    public CacheCleanerViewModel()
    {
        Cards.Add(new CacheCardViewModel(CleanCategory.BrowserCaches,
            "Browser Caches", "Chrome, Edge, and Firefox cache files.", "\uEBBC", _service));
        Cards.Add(new CacheCardViewModel(CleanCategory.WindowsUpdateCache,
            "Windows Update Cache", "Downloaded packages in SoftwareDistribution\\Download.", "\uE896", _service));
        Cards.Add(new CacheCardViewModel(CleanCategory.ThumbnailCache,
            "Thumbnail Cache", "Windows Explorer thumbcache_*.db files.", "\uEB9F", _service));
        Cards.Add(new CacheCardViewModel(CleanCategory.DnsCache,
            "DNS Cache", "Resolver cache flushed via ipconfig /flushdns.", "\uE968", _service));
        Cards.Add(new CacheCardViewModel(CleanCategory.Prefetch,
            "Prefetch Files", "App launch prefetch data (admin required).", "\uEA18", _service));
        Cards.Add(new CacheCardViewModel(CleanCategory.TempFiles,
            "Temp Files", "All files in %TEMP% and %LOCALAPPDATA%\\Temp.", "\uE74D", _service));

        ScanAllCommand  = new AsyncRelayCommand(ScanAllAsync);
        CleanAllCommand = new AsyncRelayCommand(CleanAllAsync);
    }

    private async Task ScanAllAsync()
    {
        StatusText = "Scanning all categories…";
        await Task.WhenAll(Cards.Select(c => c.ScanAsync()));
        StatusText = "Scan complete. Review sizes above.";
    }

    private async Task CleanAllAsync()
    {
        var cardsWithSize = Cards.Where(c => c.SizeBytes > 0).ToList();
        if (cardsWithSize.Count == 0) { StatusText = "Nothing to clean — run Scan All first."; return; }

        var confirm = MessageBox.Show(
            "Clean ALL cache categories shown above?\n\nThis cannot be undone.",
            "WinSweep – Confirm Clean All",
            MessageBoxButton.YesNo,
            MessageBoxImage.Warning);

        if (confirm != MessageBoxResult.Yes) return;

        StatusText = "Cleaning all categories…";
        long totalFreed = 0;

        foreach (var card in cardsWithSize)
        {
            await card.CleanAsync();
            totalFreed += card.FreedBytes;
        }

        StatusText = $"All done. Total freed: {ScannedItem.FormatBytes(totalFreed)}.";
    }
}

/// <summary>Represents a single cache category card on the CacheCleaner page.</summary>
public sealed class CacheCardViewModel : ObservableBase
{
    private readonly CacheCleaner  _service;
    private readonly CleanCategory _category;

    private long   _sizeBytes   = 0;
    private long   _freedBytes  = 0;
    private bool   _isScanning  = false;
    private bool   _isCleaning  = false;
    private string _statusLabel = "Not scanned";

    public string Name        { get; }
    public string Description { get; }
    public string Icon        { get; }

    public long FreedBytes
    {
        get => _freedBytes;
        private set { SetProperty(ref _freedBytes, value); OnPropertyChanged(nameof(FormattedFreed)); }
    }

    public string FormattedFreed => FreedBytes > 0
        ? $"Freed {ScannedItem.FormatBytes(FreedBytes)}"
        : string.Empty;

    public long SizeBytes
    {
        get => _sizeBytes;
        private set
        {
            SetProperty(ref _sizeBytes, value);
            OnPropertyChanged(nameof(FormattedSize));
            OnPropertyChanged(nameof(HasSize));
        }
    }

    public string FormattedSize => ScannedItem.FormatBytes(SizeBytes);
    public bool   HasSize       => SizeBytes > 0;

    public bool IsScanning
    {
        get => _isScanning;
        private set { SetProperty(ref _isScanning, value); OnPropertyChanged(nameof(CanScan)); OnPropertyChanged(nameof(CanClean)); }
    }

    public bool IsCleaning
    {
        get => _isCleaning;
        private set { SetProperty(ref _isCleaning, value); OnPropertyChanged(nameof(CanScan)); OnPropertyChanged(nameof(CanClean)); }
    }

    public bool CanScan  => !IsScanning && !IsCleaning;
    public bool CanClean => !IsScanning && !IsCleaning && SizeBytes > 0;

    public string StatusLabel
    {
        get => _statusLabel;
        private set => SetProperty(ref _statusLabel, value);
    }

    public AsyncRelayCommand ScanCommand  { get; }
    public AsyncRelayCommand CleanCommand { get; }

    public CacheCardViewModel(CleanCategory category, string name,
        string description, string icon, CacheCleaner service)
    {
        _category   = category;
        _service    = service;
        Name        = name;
        Description = description;
        Icon        = icon;

        ScanCommand  = new AsyncRelayCommand(ScanAsync,  () => CanScan);
        CleanCommand = new AsyncRelayCommand(CleanAsync, () => CanClean);
    }

    public async Task ScanAsync()
    {
        IsScanning  = true;
        StatusLabel = "Scanning…";
        try
        {
            SizeBytes   = await _service.GetSizeAsync(_category);
            StatusLabel = HasSize ? FormattedSize : "Nothing found";
        }
        catch (Exception ex) { StatusLabel = $"Error: {ex.Message}"; }
        finally              { IsScanning = false; }
    }

    public async Task CleanAsync()
    {
        if (SizeBytes == 0) return;
        IsCleaning  = true;
        StatusLabel = "Cleaning…";
        try
        {
            var result  = await _service.CleanAsync(_category,
                new Progress<string>(msg => StatusLabel = msg));
            FreedBytes  = result.SpaceFreed;
            SizeBytes   = 0;
            StatusLabel = result.HasErrors
                ? $"Done ({result.Errors.Count} errors — see log)"
                : $"Freed {result.FormattedSpaceFreed}";
        }
        catch (Exception ex) { StatusLabel = $"Error: {ex.Message}"; }
        finally              { IsCleaning = false; }
    }
}
