import Foundation
import SwiftUI

// MARK: - Developer Tools ViewModel

@MainActor
class DeveloperToolsViewModel: ObservableObject {
    @Published var devResults: [DevToolResult] = []
    @Published var totalReclaimable: Int64 = 0
    @Published var isScanning = false
    @Published var activeTab: String = "All Environments"

    let tabs = ["All Environments", "Javascript", "Containers", "Mobile (iOS/Android)"]

    private let devService = DeveloperToolsService.shared
    private let cleanup = CleanupService.shared

    var filteredResults: [DevToolResult] {
        if activeTab == "All Environments" {
            return devResults
        }
        return devResults.filter { $0.category.rawValue == activeTab }
    }

    func scanDevTools() async {
        isScanning = true
        await devService.scanAll()
        devResults = devService.results
        totalReclaimable = devService.totalReclaimable
        isScanning = false
    }

    func cleanDevTool(_ tool: DevToolResult) async {
        let safeFiles = tool.items.filter { $0.isSafeToDelete }
        let _ = await cleanup.moveToTrash(files: safeFiles)
        await scanDevTools()
    }
}
