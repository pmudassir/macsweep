import Foundation
import SwiftUI

// MARK: - Disk Usage Service

@MainActor
class DiskUsageService: ObservableObject {
    static let shared = DiskUsageService()

    @Published var isLoading = false

    private let fileManager = FileManager.default

    private init() {}

    // MARK: - Public API (used by DashboardViewModel)

    /// Returns current disk usage synchronously from system APIs
    func getDiskUsage() -> DiskUsage {
        do {
            let url = URL(fileURLWithPath: "/")
            let values = try url.resourceValues(
                forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey]
            )
            let total = Int64(values.volumeTotalCapacity ?? 0)
            let free  = Int64(values.volumeAvailableCapacity ?? 0)
            let used  = total - free
            return DiskUsage(totalSpace: total, usedSpace: used, freeSpace: free)
        } catch {
            return .empty
        }
    }

    /// Returns storage breakdown by home directory category (async)
    func getStorageBreakdown() async -> [StorageCategoryInfo] {
        let home = fileManager.homeDirectoryForCurrentUser.path

        let definitions: [(String, String, String, String)] = [
            ("Applications", "app.fill",                  "\(home)/Applications", "4F46E5"),
            ("Documents",    "doc.fill",                  "\(home)/Documents",    "7C3AED"),
            ("Downloads",    "arrow.down.circle.fill",    "\(home)/Downloads",    "2563EB"),
            ("Desktop",      "desktopcomputer",           "\(home)/Desktop",      "059669"),
            ("Library",      "books.vertical.fill",       "\(home)/Library",      "D97706"),
            ("Movies",       "film.fill",                 "\(home)/Movies",       "DC2626"),
            ("Music",        "music.note",                "\(home)/Music",        "EC4899"),
            ("Pictures",     "photo.fill",                "\(home)/Pictures",     "0891B2"),
        ]

        var result: [StorageCategoryInfo] = []
        for (name, icon, path, color) in definitions {
            let size = directorySize(atPath: path)
            result.append(StorageCategoryInfo(name: name, icon: icon, size: size, color: color))
        }

        return result.sorted { $0.size > $1.size }
    }

    // MARK: - Helpers

    /// Called by DeveloperToolsService — accepts a path String
    func directorySize(atPath path: String) -> Int64 {
        return directorySize(at: path)
    }

    /// Called by DeveloperToolsService — accepts a path String with `at:` label
    func directorySize(at path: String) -> Int64 {
        var total: Int64 = 0
        guard let enumerator = fileManager.enumerator(
            at: URL(fileURLWithPath: path),
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return 0 }

        for case let fileURL as URL in enumerator {
            guard let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize
            else { continue }
            total += Int64(size)
        }
        return total
    }
}
