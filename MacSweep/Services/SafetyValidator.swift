import Foundation

// MARK: - Safety Validator

class SafetyValidator {
    static let shared = SafetyValidator()

    private init() {}

    /// Check if a file path is safe to delete
    func isSafeToDelete(path: String) -> Bool {
        let expandedPath = (path as NSString).expandingTildeInPath

        // Never delete root level system directories
        for protectedPath in Constants.protectedPaths {
            if expandedPath == protectedPath || expandedPath.hasPrefix(protectedPath + "/") {
                // Exception: allow deleting within ~/Library/Caches, ~/Library/Logs, etc.
                let home = FileManager.default.homeDirectoryForCurrentUser.path
                if expandedPath.hasPrefix(home) {
                    return isUserPathSafeToDelete(expandedPath, home: home)
                }
                return false
            }
        }

        return true
    }

    /// Check if a user-home path is safe to delete
    private func isUserPathSafeToDelete(_ path: String, home: String) -> Bool {
        let relativePath = String(path.dropFirst(home.count + 1))

        // Check protected home paths
        for protectedHome in Constants.protectedHomePaths {
            if relativePath == protectedHome {
                return false
            }
        }

        // Allow: ~/Library/Caches/*, ~/Library/Logs/*, DerivedData, etc.
        let safePatterns = [
            "Library/Caches/",
            "Library/Logs/",
            "Library/Developer/Xcode/DerivedData",
            "Library/Developer/Xcode/Archives",
            "Library/Caches/CocoaPods",
            "Library/Caches/Google/Chrome",
            "Library/Caches/com.apple.Safari",
            "Library/Caches/Yarn",
            ".npm/",
            ".expo/",
            ".Trash/",
            "Downloads/",
        ]

        for pattern in safePatterns {
            if relativePath.hasPrefix(pattern) {
                return true
            }
        }

        // node_modules anywhere is safe
        if relativePath.contains("node_modules") {
            return true
        }

        return false
    }

    /// Determine impact score for a file
    func impactScore(for path: String, category: ScanCategory) -> ImpactScore {
        switch category {
        case .developerFiles:
            if path.contains("DerivedData") { return .critical }
            if path.contains("node_modules") { return .medium }
            return .medium
        case .browserCaches:
            return .medium
        case .systemLogs:
            return .low
        case .trashBin:
            return .low
        case .downloads:
            return .medium
        case .userCaches:
            return .low
        default:
            return .low
        }
    }

    /// Check if a file is currently in use
    func isFileInUse(at path: String) -> Bool {
        // Simple check: try to get an exclusive lock
        let fileDescriptor = open(path, O_RDONLY)
        guard fileDescriptor >= 0 else { return false }

        let lockResult = flock(fileDescriptor, LOCK_EX | LOCK_NB)
        if lockResult == 0 {
            flock(fileDescriptor, LOCK_UN)
            close(fileDescriptor)
            return false  // not in use
        } else {
            close(fileDescriptor)
            return true  // in use
        }
    }
}
