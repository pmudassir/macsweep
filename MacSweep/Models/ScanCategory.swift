import Foundation

// MARK: - Scan Category

enum ScanCategory: String, CaseIterable, Identifiable, Codable {
    case userCaches
    case systemLogs
    case browserCaches
    case developerFiles
    case downloads
    case trashBin
    case appSupport
    case mailAttachments
    case iosBackups

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .userCaches: return "User Caches"
        case .systemLogs: return "System Logs"
        case .browserCaches: return "Browser Caches"
        case .developerFiles: return "Developer Files"
        case .downloads: return "Downloads"
        case .trashBin: return "Trash Bin"
        case .appSupport: return "App Support"
        case .mailAttachments: return "Mail Attachments"
        case .iosBackups: return "iOS Backups"
        }
    }

    var icon: String {
        switch self {
        case .userCaches: return "cylinder.split.1x2"
        case .systemLogs: return "doc.text"
        case .browserCaches: return "globe"
        case .developerFiles: return "chevron.left.forwardslash.chevron.right"
        case .downloads: return "arrow.down.circle"
        case .trashBin: return "trash"
        case .appSupport: return "app.badge"
        case .mailAttachments: return "envelope"
        case .iosBackups: return "iphone"
        }
    }

    var description: String {
        switch self {
        case .userCaches: return "Temporary files stored by applications."
        case .systemLogs: return "Diagnostic reports, system activity logs, and legacy error reports."
        case .browserCaches: return "Temporary internet files and history from Chrome, Safari, and Firefox."
        case .developerFiles: return "Derived data, build artifacts, and CocoaPods cache from Xcode."
        case .downloads: return "Old installers and forgotten files in your downloads folder."
        case .trashBin: return "Files you've deleted but are still occupying disk space."
        case .appSupport: return "Application support data and leftover files."
        case .mailAttachments: return "Cached email attachments from Mail app."
        case .iosBackups: return "iOS device backups stored on this Mac."
        }
    }

    var scanPaths: [String] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        switch self {
        case .userCaches:
            return ["\(home)/\(Constants.ScanPaths.userCaches)"]
        case .systemLogs:
            return ["\(home)/\(Constants.ScanPaths.systemLogs)"]
        case .browserCaches:
            return [
                "\(home)/\(Constants.ScanPaths.chromeCache)",
                "\(home)/\(Constants.ScanPaths.safariCache)",
                "\(home)/\(Constants.ScanPaths.arcCache)",
                "\(home)/\(Constants.ScanPaths.firefoxCache)",
            ]
        case .developerFiles:
            return [
                "\(home)/\(Constants.ScanPaths.xcodeDeriveDData)",
                "\(home)/\(Constants.ScanPaths.xcodeArchives)",
                "\(home)/\(Constants.ScanPaths.cocoapodsCache)",
            ]
        case .downloads:
            return ["\(home)/\(Constants.ScanPaths.downloads)"]
        case .trashBin:
            return ["\(home)/.Trash"]
        case .appSupport:
            return ["\(home)/\(Constants.ScanPaths.appSupport)"]
        case .mailAttachments:
            return ["\(home)/Library/Mail"]
        case .iosBackups:
            return ["\(home)/\(Constants.ScanPaths.iosBackups)"]
        }
    }

    var tabLabel: String {
        switch self {
        case .userCaches: return "Application Caches"
        case .systemLogs: return "Developer Logs"
        case .browserCaches: return "Application Caches"
        case .developerFiles: return "Developer Logs"
        case .downloads: return "Large Files"
        case .trashBin: return "Trash Bin"
        case .appSupport: return "Application Caches"
        case .mailAttachments: return "System Junk"
        case .iosBackups: return "Large Files"
        }
    }
}

// MARK: - Scan Result for a Category
struct CategoryScanResult: Identifiable {
    let id = UUID()
    let category: ScanCategory
    var totalSize: Int64
    var fileCount: Int
    var files: [ScannedFile]
    var isScanning: Bool = false

    var formattedSize: String {
        FileSize(totalSize).shortFormatted
    }
}
