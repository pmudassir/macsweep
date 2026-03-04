import Foundation
import SwiftUI

// MARK: - Scan Results ViewModel

@MainActor
class ScanResultsViewModel: ObservableObject {
    @Published var scanResults: [ScanCategory: CategoryScanResult] = [:]
    @Published var isScanning = false
    @Published var scanProgress: Double = 0
    @Published var totalCleanable: Int64 = 0
    @Published var showCleanConfirmation = false
    @Published var categoryToClean: ScanCategory?

    private let scanner = ScannerService.shared
    private let cleanup = CleanupService.shared

    func startScan() async {
        isScanning = true
        await scanner.scanAll()
        scanResults = scanner.results
        totalCleanable = scanner.totalCleanableSize
        isScanning = false
    }

    func cleanCategory(_ category: ScanCategory) async {
        guard let result = scanResults[category] else { return }
        let _ = await cleanup.cleanCategory(result)
        // Re-scan that category
        let newResult = await scanner.scanCategory(category)
        scanResults[category] = newResult
        totalCleanable = scanResults.values.reduce(0) { $0 + $1.totalSize }
    }

    func cleanAll() async {
        for (_, result) in scanResults {
            let _ = await cleanup.cleanCategory(result)
        }
        await startScan()
    }
}
