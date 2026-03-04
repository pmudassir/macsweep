import Foundation

// MARK: - Impact Score

enum ImpactScore: String, Codable, CaseIterable {
    case low
    case medium
    case critical

    var displayName: String {
        rawValue.uppercased()
    }

    var color: String {
        switch self {
        case .low: return "3C83F6"
        case .medium: return "F59E0B"
        case .critical: return "EF4444"
        }
    }
}

// MARK: - Scanned File

struct ScannedFile: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let path: String
    let size: Int64
    let category: ScanCategory
    let modifiedDate: Date?
    let isSafeToDelete: Bool
    let impactScore: ImpactScore

    var formattedSize: String {
        FileSize(size).shortFormatted
    }

    var locationDisplayPath: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }

    var categoryLabel: String {
        switch category {
        case .developerFiles: return "Developer"
        case .browserCaches, .userCaches, .appSupport: return "System"
        case .downloads, .iosBackups: return "Large Files"
        default: return "System"
        }
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ScannedFile, rhs: ScannedFile) -> Bool {
        lhs.id == rhs.id
    }
}
