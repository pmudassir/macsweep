import Foundation
import SwiftUI

// MARK: - Cleanup ViewModel

@MainActor
class CleanupViewModel: ObservableObject {
    @Published var allFiles: [ScannedFile] = []
    @Published var selectedFiles: Set<UUID> = []
    @Published var activeTab: String = "System Junk"
    @Published var isCleaningUp = false
    @Published var showConfirmation = false
    @Published var searchQuery = ""

    let tabs = ["System Junk", "Application Caches", "Large Files", "Developer Logs", "Trash Bin"]

    private let scanner = ScannerService.shared
    private let cleanup = CleanupService.shared

    var filteredFiles: [ScannedFile] {
        var files = allFiles

        // Filter by tab
        switch activeTab {
        case "System Junk":
            files = files.filter { $0.category == .systemLogs || $0.category == .mailAttachments }
        case "Application Caches":
            files = files.filter {
                $0.category == .userCaches || $0.category == .browserCaches
                    || $0.category == .appSupport
            }
        case "Large Files":
            files = files.filter { $0.category == .downloads || $0.category == .iosBackups }
                .sorted { $0.size > $1.size }
        case "Developer Logs":
            files = files.filter { $0.category == .developerFiles }
        case "Trash Bin":
            files = files.filter { $0.category == .trashBin }
        default:
            break
        }

        // Filter by search
        if !searchQuery.isEmpty {
            files = files.filter {
                $0.name.localizedCaseInsensitiveContains(searchQuery)
                    || $0.path.localizedCaseInsensitiveContains(searchQuery)
            }
        }

        return files
    }

    var selectedSize: Int64 {
        allFiles.filter { selectedFiles.contains($0.id) }.reduce(0) { $0 + $1.size }
    }

    var selectedCount: Int {
        selectedFiles.count
    }

    var storageGainPercent: Double {
        let diskUsage = DiskUsageService.shared.getDiskUsage()
        guard diskUsage.totalSpace > 0 else { return 0 }
        return Double(selectedSize) / Double(diskUsage.totalSpace) * 100
    }

    func loadFiles() async {
        await scanner.scanAll()
        allFiles = scanner.results.values.flatMap { $0.files }
    }

    func toggleSelection(_ file: ScannedFile) {
        if selectedFiles.contains(file.id) {
            selectedFiles.remove(file.id)
        } else {
            selectedFiles.insert(file.id)
        }
    }

    func selectAll() {
        for file in filteredFiles {
            selectedFiles.insert(file.id)
        }
    }

    func deselectAll() {
        selectedFiles.removeAll()
    }

    func deleteSelected() async {
        let filesToDelete = allFiles.filter { selectedFiles.contains($0.id) }
        isCleaningUp = true
        let _ = await cleanup.moveToTrash(files: filesToDelete)
        selectedFiles.removeAll()
        await loadFiles()
        isCleaningUp = false
    }
}
