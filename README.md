<div align="center">

# 🧹 MacSweep · WinSweep

**One cleaner. Two platforms. Zero clutter.**

*A fast, lightweight system cleaner for macOS & Windows — removes junk files, clears cache, and manages startup items to keep your machine running at peak performance.*

<br/>

[![macOS Download](https://img.shields.io/github/v/release/pmudassir/macsweep?label=Download%20for%20macOS&style=for-the-badge&logo=apple&color=000000)](https://github.com/pmudassir/macsweep/releases/latest)
&nbsp;&nbsp;
[![Windows Download](https://img.shields.io/github/v/release/pmudassir/macsweep?label=Download%20for%20Windows&style=for-the-badge&logo=windows&color=0078D4)](https://github.com/pmudassir/macsweep/releases/latest)

</div>

---

## ⬇️ Download

Go to the **[Releases page](https://github.com/pmudassir/macsweep/releases/latest)** and download the file for your platform:

| Platform | File to Download | Format |
|----------|-----------------|--------|
| 🍎 **macOS** | `MacSweep-vX.X.X-mac.dmg` | DMG disk image |
| 🪟 **Windows** | `WinSweep-vX.X.X-win-x64.zip` | ZIP archive |

---

## 🍎 macOS — Installation

### Step 1 — Download the DMG
Go to [Releases](https://github.com/pmudassir/macsweep/releases/latest) and download:
```
MacSweep-vX.X.X-mac.dmg
```

### Step 2 — Open the DMG
- Double-click the downloaded `.dmg` file
- A disk image window will open

### Step 3 — Install the App
- Drag **MacSweep.app** into the **Applications** folder shortcut inside the window
- Eject the disk image

### Step 4 — Launch MacSweep
- Open **Launchpad** or **Finder → Applications**
- Double-click **MacSweep**

> ⚠️ **"MacSweep is damaged or incomplete" error?**
> This happens because macOS quarantines downloaded unsigned apps. To fix it, open **Terminal** and run:
> ```bash
> xattr -cr /Applications/MacSweep.app
> ```
> Then launch the app again — it will work!

> 💡 **Gatekeeper warning on first launch?**
> Right-click the app → **Open** → click **Open** in the dialog.
> This only needs to be done once.

---

## 🪟 Windows — Installation

### Step 1 — Download the ZIP
Go to [Releases](https://github.com/pmudassir/macsweep/releases/latest) and download:
```
WinSweep-vX.X.X-win-x64.zip
```

### Step 2 — Extract the ZIP
- Right-click the downloaded ZIP file
- Select **"Extract All..."**
- Choose your preferred folder (e.g. `C:\Program Files\WinSweep`)

### Step 3 — Run the App
- Open the extracted folder
- Double-click **`WinSweep.exe`**
- Right-click → **"Run as Administrator"** for full cleaning access

> ✅ **No installation wizard. No .NET required. Just extract and run!**

> ⚠️ **Windows SmartScreen warning?**
> Click **"More info"** → **"Run anyway"**. This is a known prompt for new unsigned apps.

---

## 💻 System Requirements

### macOS
| Requirement | Details |
|-------------|---------|
| OS | macOS 13 Ventura or later |
| Architecture | Apple Silicon (M1/M2/M3) or Intel |
| Disk Space | ~25 MB |
| Permissions | Standard user (some features need admin) |

### Windows
| Requirement | Details |
|-------------|---------|
| OS | Windows 10 or Windows 11 (64-bit) |
| Architecture | x64 (Intel / AMD) |
| .NET Runtime | ❌ Not required (self-contained) |
| Permissions | Administrator recommended |
| Disk Space | ~80 MB |

---

## ✨ Features

| Feature | macOS | Windows |
|---------|-------|---------|
| 🗑️ **Junk File Cleaner** — Remove temp files, logs & clutter | ✅ | ✅ |
| 🗂️ **Cache Cleaner** — Clear browser & system cache | ✅ | ✅ |
| 🚀 **Startup Manager** — Disable unnecessary startup programs | ✅ | ✅ |
| 📊 **Storage Analyzer** — See what's eating your disk space | ✅ | ✅ |
| 🔒 **Safe Cleaning** — Only removes files safe to delete | ✅ | ✅ |

---

## 🖼️ Screenshots

> *(Screenshots coming soon)*

---

## ❓ Frequently Asked Questions

**Q: Which file do I download — DMG or ZIP?**
> - **Mac users** → download the `.dmg` file
> - **Windows users** → download the `.zip` file

**Q: Do I need to install .NET on Windows?**
> No! WinSweep is fully self-contained. Everything it needs is bundled inside the ZIP.

**Q: macOS says "MacSweep is damaged or incomplete." How do I fix it?**
> Open **Terminal** and run:
> ```bash
> xattr -cr /Applications/MacSweep.app
> ```
> Then launch the app again. This removes the macOS quarantine flag from downloaded apps.

**Q: macOS says the app is from an unidentified developer. What do I do?**
> Right-click the app → **Open** → click **Open**. This bypasses Gatekeeper for unsigned apps and only needs to be done once.

**Q: Windows Defender / Antivirus flagged the app. Is it safe?**
> Yes, it's safe. New unsigned apps are sometimes flagged by antivirus software.
> Click **"More info" → "Run anyway"** in the Windows SmartScreen prompt.

**Q: Do I need Administrator access on Windows?**
> Some cleaning features (like system temp files) require Admin rights.
> Right-click `WinSweep.exe` → **Run as Administrator** for full functionality.

**Q: How do I update to a newer version?**
> **macOS:** Download the new `.dmg`, open it, and drag the new app over your old one in Applications.
> **Windows:** Download the new `.zip`, extract it, and replace your old folder.

---

## 📋 Changelog

See [Releases](https://github.com/pmudassir/macsweep/releases) for full version history and release notes.

---

## 🐛 Found a Bug?

Please [open an issue](https://github.com/pmudassir/macsweep/issues) and include:
- Your OS and version (e.g. macOS 14.4, Windows 11)
- What you were doing when it happened
- Any error messages shown

---

## 📄 License

MIT License — free to use, modify, and distribute.

---

<p align="center">Made with ❤️ for macOS & Windows users</p>
