import Foundation

struct Constants {
    // MARK: - Protected System Paths (never delete)
    static let protectedPaths: Set<String> = [
        "/System",
        "/usr",
        "/bin",
        "/sbin",
        "/Applications",
        "/Library",
        "/private/var",
        "/private/etc",
        "/cores",
        "/dev",
        "/etc",
        "/tmp",
        "/var",
    ]

    // Paths within user home that are critical
    static let protectedHomePaths: Set<String> = [
        "Desktop",
        "Documents",
        "Pictures",
        "Music",
        "Movies",
        ".ssh",
        ".gnupg",
        ".gitconfig",
        ".zshrc",
        ".bashrc",
        ".bash_profile",
        "Library/Keychains",
        "Library/Preferences",
        "Library/Application Support/com.apple.",
    ]

    // MARK: - Scan Target Paths (relative to home)
    struct ScanPaths {
        static let userCaches = "Library/Caches"
        static let systemLogs = "Library/Logs"
        static let appSupport = "Library/Application Support"
        static let downloads = "Downloads"
        static let mailAttachments = "Library/Mail/V*/MailData/Attachments"

        // Browser caches
        static let chromeCache = "Library/Caches/Google/Chrome"
        static let safariCache = "Library/Caches/com.apple.Safari"
        static let arcCache = "Library/Caches/company.thebrowser.Browser"
        static let firefoxCache = "Library/Caches/Firefox"

        // Developer paths
        static let xcodeDeriveDData = "Library/Developer/Xcode/DerivedData"
        static let xcodeArchives = "Library/Developer/Xcode/Archives"
        static let cocoapodsCache = "Library/Caches/CocoaPods"
        static let npmCache = ".npm"
        static let pnpmStore = "Library/pnpm/store"
        static let yarnCache = "Library/Caches/Yarn"
        static let expoCache = ".expo"

        // iOS Backups
        static let iosBackups = "Library/Application Support/MobileSync/Backup"
    }

    // MARK: - Age thresholds
    static let defaultDownloadAgeDays = 30
    static let defaultTrashAgeDays = 30

    // MARK: - App Info
    static let appVersion = "1.0.0"
    static let appName = "MacSweep"
}
