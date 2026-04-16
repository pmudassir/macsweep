import Foundation

// MARK: - Scanner Service

@MainActor
class ScannerService: ObservableObject {
    static let shared = ScannerService()

    @Published var isScanning = false
    @Published var progress: Double = 0
    @Published var currentPath: String = ""
    @Published var results: [CategoryScanResult] = []
    @Published var totalSize: Int64 = 0

    private let fileManager = FileManager.default
    private let safetyValidator = SafetyValidator.shared
    private var scanTask: Task<Void, Never>?

    private init() {}

    // MARK: - Public API

    /// Scan all categories
    func scanAll() async {
        await scan(categories: ScanCategory.allCases)
    }

    /// Scan specific categories
    func scan(categories: [ScanCategory]) async {
        isScanning = true
        progress   = 0
        results    = []
        totalSize  = 0

        let step = 1.0 / Double(max(categories.count, 1))

        for (index, category) in categories.enumerated() {
            currentPath = "Scanning \(category.displayName)..."
            let result  = await scanCategory(category)
            results.append(result)
            totalSize  += result.totalSize
            progress    = Double(index + 1) * step
        }

        currentPath = "Scan complete"
        isScanning  = false
    }

    /// Cancel an in-progress scan
    func cancelScan() {
        scanTask?.cancel()
        isScanning  = false
        currentPath = "Scan cancelled"
    }

    // MARK: - Private Scanning

    private func scanCategory(_ category: ScanCategory) async -> CategoryScanResult {
        var files: [ScannedFile] = []
        var totalSize: Int64     = 0

        for path in category.scanPaths {
            guard fileManager.fileExists(atPath: path) else { continue }

            let categoryFiles = await scanDirectory(path: path, category: category)
            files.append(contentsOf: categoryFiles)
            totalSize += categoryFiles.reduce(0) { $0 + $1.size }
        }

        return CategoryScanResult(
            category:  category,
            totalSize: totalSize,
            fileCount: files.count,
            files:     files
        )
    }

    private func scanDirectory(path: String, category: ScanCategory) async -> [ScannedFile] {
        var scannedFiles: [ScannedFile] = []

        let url = URL(fileURLWithPath: path)
        guard let enumerator = fileManager.enumerator(
            at:                         url,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .isRegularFileKey],
            options:                    [.skipsHiddenFiles]
        ) else { return [] }

        for case let fileURL as URL in enumerator {
            guard Task.isCancelled == false else { break }

            guard
                let values    = try? fileURL.resourceValues(forKeys: [
                    .fileSizeKey, .contentModificationDateKey, .isRegularFileKey
                ]),
                values.isRegularFile == true,
                let size      = values.fileSize
            else { continue }

            let filePath  = fileURL.path
            let isSafe    = safetyValidator.isSafeToDelete(path: filePath)
            let impact    = impactScore(forSize: Int64(size))

            let file = ScannedFile(
                name:          fileURL.lastPathComponent,
                path:          filePath,
                size:          Int64(size),
                category:      category,
                modifiedDate:  values.contentModificationDate,
                isSafeToDelete: isSafe,
                impactScore:   impact
            )
            scannedFiles.append(file)
        }

        return scannedFiles
    }

    // MARK: - Helpers

    private func impactScore(forSize size: Int64) -> ImpactScore {
        switch size {
        case ..<(10 * 1024 * 1024):          return .low        // < 10 MB
        case ..<(100 * 1024 * 1024):         return .medium     // < 100 MB
        default:                             return .critical    // ≥ 100 MB
        }
    }
}
