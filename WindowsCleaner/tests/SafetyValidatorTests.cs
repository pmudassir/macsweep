using System.IO;
using WinSweep.Core.Services;
using Xunit;

namespace WinSweep.Tests;

/// <summary>Unit tests for SafetyValidator — the most safety-critical component.</summary>
public sealed class SafetyValidatorTests
{
    private readonly SafetyValidator _sut = SafetyValidator.Shared;

    // ── Protected system paths must NEVER be safe to delete ──────────────

    [Theory]
    [InlineData(@"C:\Windows")]
    [InlineData(@"C:\Windows\System32")]
    [InlineData(@"C:\Windows\SysWOW64")]
    [InlineData(@"C:\Program Files")]
    [InlineData(@"C:\Program Files (x86)")]
    public void IsSafeToDelete_ReturnsFalse_ForSystemRoots(string path)
    {
        // Only validate paths that actually exist on this machine
        if (!Directory.Exists(path) && !File.Exists(path)) return;
        Assert.False(_sut.IsSafeToDelete(path));
    }

    // ── Sub-paths of System32 must be blocked ─────────────────────────────

    [Fact]
    public void IsSafeToDelete_ReturnsFalse_ForSystem32SubPath()
    {
        string system32 = Environment.GetFolderPath(Environment.SpecialFolder.System);
        string target   = Path.Combine(system32, "notepad.exe");
        Assert.False(_sut.IsSafeToDelete(target));
    }

    // ── Temp paths must be safe ───────────────────────────────────────────

    [Fact]
    public void IsSafeToDelete_ReturnsTrue_ForTempSubFile()
    {
        string tempFile = Path.Combine(Path.GetTempPath(), "winsweep_test_dummy.tmp");
        Assert.True(_sut.IsSafeToDelete(tempFile));
    }

    [Fact]
    public void IsSafeToDelete_ReturnsTrue_ForLocalAppDataTemp()
    {
        string localTemp = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "Temp", "winsweep_test.tmp");
        Assert.True(_sut.IsSafeToDelete(localTemp));
    }

    // ── Browser cache paths must be allowed ──────────────────────────────

    [Fact]
    public void IsSafeToDelete_ReturnsTrue_ForChromeCache()
    {
        string chrome = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "Google", "Chrome", "User Data", "Default", "Cache", "data_0");
        Assert.True(_sut.IsSafeToDelete(chrome));
    }

    // ── Null / empty must be rejected ────────────────────────────────────

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("   ")]
    public void IsSafeToDelete_ReturnsFalse_ForNullOrEmpty(string? path)
    {
        Assert.False(_sut.IsSafeToDelete(path!));
    }

    // ── System-critical startup names ────────────────────────────────────

    [Theory]
    [InlineData("SecurityHealth")]
    [InlineData("Windows Defender")]
    [InlineData("WindowsDefender")]
    public void IsSystemCriticalStartup_ReturnsTrue_ForKnownNames(string name)
    {
        Assert.True(_sut.IsSystemCriticalStartup(name));
    }

    [Fact]
    public void IsSystemCriticalStartup_ReturnsFalse_ForRandomApp()
    {
        Assert.False(_sut.IsSystemCriticalStartup("Spotify"));
    }
}
