import Foundation

// MARK: - Disk Usage

struct DiskUsage {
    let totalSpace: Int64
    let usedSpace: Int64
    let freeSpace: Int64

    var percentUsed: Double {
        guard totalSpace > 0 else { return 0 }
        return Double(usedSpace) / Double(totalSpace) * 100
    }

    var percentFree: Double {
        guard totalSpace > 0 else { return 0 }
        return Double(freeSpace) / Double(totalSpace) * 100
    }

    var formattedTotal: String { FileSize(totalSpace).shortFormatted }
    var formattedUsed: String { FileSize(usedSpace).shortFormatted }
    var formattedFree: String { FileSize(freeSpace).shortFormatted }

    static var empty: DiskUsage {
        DiskUsage(totalSpace: 0, usedSpace: 0, freeSpace: 0)
    }
}

// MARK: - Storage Category (Dashboard)

struct StorageCategoryInfo: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let size: Int64
    let color: String

    var formattedSize: String {
        FileSize(size).shortFormatted
    }
}
