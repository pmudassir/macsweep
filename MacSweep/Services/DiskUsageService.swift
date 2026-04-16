import Foundation

// MARK: - Disk Usage Service

@MainActor
class DiskUsageService: ObservableObject {
    static let shared = DiskUsageService()

    @Published var diskUsage: DiskUsage = .empty
    @Published var isLoading = false
    @Published var storageCategories: [StorageCategoryInfo] = []

    private let fileManager = FileManager.default

    private init() {}

    // MARK: - Fetch Disk Usage

    func fetchDiskUsage() async {
        isLoading = true
        defer { isLoading = false }

        diskUsage = await calculateDiskUsage()
        storageCategories = await calculateStorageCategories()
    }

    private func calculateDiskUsage() async -> DiskUsage {
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

    private func calculateStorageCategories() async -> [StorageCategoryInfo] {
        let home = fileManager.homeDirectoryForCurrentUser.path

        let categories: [(String, String, String)] = [
            ("Applications", "app.fill", "\(home)/Applications"),
            ("Documents",    "doc.fill", "\(home)/Documents"),
            ("Downloads",    "arrow.down.circle.fill", "\(home)/Downloads"),
            ("Desktop",      "desktopcomputer", "\(home)/Desktop"),
            ("Library",      "books.vertical.fill", "\(home)/Library"),
            ("Movies",       "film.fill", "\(home)/Movies"),
            ("Music",        "music.note", "\(home)/Music"),
            ("Pictures",     "photo.fill", "\(home)/Pictures"),
        ]

        var result: [StorageCategoryInfo] = []
        for (name, icon, path) in categories {
            let size = directorySize(atPath: path)
            let colors = ["4F46E5", "7C3AED", "2563EB", "059669", "D97706", "DC2626", "EC4899", "0891B2"]
            let color = colors[result.count % colors.count]
            result.append(StorageCategoryInfo(name: name, icon: icon, size: size, color: color))
        }

        return result.sorted { $0.size > $1.size }
    }

    // MARK: - Helpers

    func directorySize(atPath path: String) -> Int64 {
        var totalSize: Int64 = 0
        guard let enumerator = fileManager.enumerator(
            at: URL(fileURLWithPath: path),
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return 0 }

        for case let fileURL as URL in enumerator {
            guard let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize else { continue }
            totalSize += Int64(size)
        }
        return totalSize
    }
}
