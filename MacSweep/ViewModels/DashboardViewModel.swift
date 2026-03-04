import Foundation
import SwiftUI

// MARK: - Dashboard ViewModel

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var diskUsage: DiskUsage = .empty
    @Published var storageCategories: [StorageCategoryInfo] = []
    @Published var isLoading = false
    @Published var lastScanTime: Date?

    private let diskService = DiskUsageService.shared

    func loadData() async {
        isLoading = true
        diskUsage = diskService.getDiskUsage()
        storageCategories = await diskService.getStorageBreakdown()
        lastScanTime = Date()
        isLoading = false
    }
}
