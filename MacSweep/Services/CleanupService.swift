import AppKit
import Foundation

// MARK: - Cleanup Service

@MainActor
class CleanupService: ObservableObject {
    static let shared = CleanupService()

    @Published var isCleaningUp = false
    @Published var lastResult: CleanupResult?

    private let fileManager = FileManager.default
    private let safetyValidator = SafetyValidator.shared

    private init() {}

    /// Move files to Trash (safe delete)
    func moveToTrash(files: [ScannedFile]) async -> CleanupResult {
        isCleaningUp = true
        var filesRemoved = 0
        var spaceFreed: Int64 = 0
        var errors: [CleanupError] = []

        for file in files {
            // Validate safety
            guard file.isSafeToDelete else {
                errors.append(CleanupError(
                    filePath: file.path,
                    message: "File is not safe to delete"
                ))
                continue
            }

            guard safetyValidator.isSafeToDelete(path: file.path) else {
                errors.append(CleanupError(
                    filePath: file.path,
                    message: "Blocked by safety validator"
                ))
                continue
            }

            do {
                let url = URL(fileURLWithPath: file.path)
                try fileManager.trashItem(at: url, resultingItemURL: nil)
                filesRemoved += 1
                spaceFreed += file.size
            } catch {
                errors.append(CleanupError(
                    filePath: file.path,
                    message: error.localizedDescription
                ))
            }
        }

        let result = CleanupResult(
            filesRemoved: filesRemoved,
            spaceFreed: spaceFreed,
            errors: errors
        )

        lastResult = result
        isCleaningUp = false
        return result
    }

    /// Permanently delete files
    func permanentDelete(files: [ScannedFile]) async -> CleanupResult {
        isCleaningUp = true
        var filesRemoved = 0
        var spaceFreed: Int64 = 0
        var errors: [CleanupError] = []

        for file in files {
            guard file.isSafeToDelete,
                safetyValidator.isSafeToDelete(path: file.path)
            else {
                errors.append(CleanupError(
                    filePath: file.path,
                    message: "Not safe to delete"
                ))
                continue
            }

            do {
                try fileManager.removeItem(atPath: file.path)
                filesRemoved += 1
                spaceFreed += file.size
            } catch {
                errors.append(CleanupError(
                    filePath: file.path,
                    message: error.localizedDescription
                ))
            }
        }

        let result = CleanupResult(
            filesRemoved: filesRemoved,
            spaceFreed: spaceFreed,
            errors: errors
        )

        lastResult = result
        isCleaningUp = false
        return result
    }

    /// Delete all files in a category
    func cleanCategory(_ result: CategoryScanResult) async -> CleanupResult {
        let safeFiles = result.files.filter { $0.isSafeToDelete }
        return await moveToTrash(files: safeFiles)
    }

    /// Empty Trash
    func emptyTrash() async -> CleanupResult {
        isCleaningUp = true

        let trashPath =
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".Trash").path
        var filesRemoved = 0
        var spaceFreed: Int64 = 0
        var errors: [CleanupError] = []

        if let contents = try? fileManager.contentsOfDirectory(atPath: trashPath) {
            for item in contents {
                let itemPath = (trashPath as NSString).appendingPathComponent(item)
                do {
                    let attrs = try fileManager.attributesOfItem(atPath: itemPath)
                    let size = attrs[.size] as? Int64 ?? 0
                    try fileManager.removeItem(atPath: itemPath)
                    filesRemoved += 1
                    spaceFreed += size
                } catch {
                    errors.append(CleanupError(
                        filePath: itemPath,
                        message: error.localizedDescription
                    ))
                }
            }
        }

        let result = CleanupResult(
            filesRemoved: filesRemoved,
            spaceFreed: spaceFreed,
            errors: errors
        )

        lastResult = result
        isCleaningUp = false
        return result
    }
}
