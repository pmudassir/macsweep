import Foundation

// MARK: - Cleanup Result

struct CleanupResult {
    let filesRemoved: Int
    let spaceFreed: Int64
    let errors: [CleanupError]

    var formattedSpaceFreed: String {
        FileSize(spaceFreed).shortFormatted
    }

    var hasErrors: Bool {
        !errors.isEmpty
    }

    static var empty: CleanupResult {
        CleanupResult(filesRemoved: 0, spaceFreed: 0, errors: [])
    }
}

struct CleanupError: Identifiable {
    let id = UUID()
    let filePath: String
    let message: String
}
