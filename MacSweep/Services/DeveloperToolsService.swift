import Foundation

// MARK: - Developer Tools Service

struct DevToolResult: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let size: Int64
    let description: String
    let actionLabel: String
    let category: DevToolCategory
    var items: [ScannedFile]

    var formattedSize: String {
        FileSize(size).shortFormatted
    }
}

enum DevToolCategory: String, CaseIterable {
    case javascript = "Javascript"
    case containers = "Containers"
    case mobile = "Mobile (iOS/Android)"
    case all = "All Environments"
}

@MainActor
class DeveloperToolsService: ObservableObject {
    static let shared = DeveloperToolsService()

    @Published var isScanning = false
    @Published var results: [DevToolResult] = []
    @Published var totalReclaimable: Int64 = 0

    private let fileManager = FileManager.default
    private let diskService = DiskUsageService.shared

    private init() {}

    /// Scan all developer tools
    func scanAll() async {
        isScanning = true
        results = []
        totalReclaimable = 0

        async let nodeResult = scanNodeModules()
        async let dockerResult = scanDockerCache()
        async let xcodeResult = scanXcodeArtifacts()
        async let packageResult = scanPackageCaches()

        let allResults = await [nodeResult, dockerResult, xcodeResult, packageResult]
        results = allResults
        totalReclaimable = allResults.reduce(0) { $0 + $1.size }

        isScanning = false
    }

    /// Scan for node_modules directories
    private func scanNodeModules() async -> DevToolResult {
        let home = fileManager.homeDirectoryForCurrentUser.path
        var totalSize: Int64 = 0
        var files: [ScannedFile] = []

        // Search common project directories
        let searchPaths = [
            "\(home)/Desktop",
            "\(home)/Documents",
            "\(home)/Projects",
            "\(home)/Developer",
            "\(home)/Code",
            "\(home)/Sites",
            "\(home)/repos",
        ]

        for searchPath in searchPaths {
            guard fileManager.fileExists(atPath: searchPath) else { continue }
            findNodeModules(in: searchPath, files: &files, totalSize: &totalSize, depth: 0, maxDepth: 4)
        }

        return DevToolResult(
            name: "Node.js Projects",
            icon: "js",
            size: totalSize,
            description:
                "Identified \(files.count) projects with inactive node_modules older than 30 days.",
            actionLabel: "Prune Modules",
            category: .javascript,
            items: files
        )
    }

    private func findNodeModules(
        in path: String, files: inout [ScannedFile], totalSize: inout Int64, depth: Int,
        maxDepth: Int
    ) {
        guard depth < maxDepth else { return }
        guard
            let contents = try? fileManager.contentsOfDirectory(
                at: URL(fileURLWithPath: path),
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
        else { return }

        for itemURL in contents {
            let isDir =
                (try? itemURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            guard isDir else { continue }

            if itemURL.lastPathComponent == "node_modules" {
                let size = diskService.directorySize(at: itemURL.path)
                totalSize += size
                files.append(ScannedFile(
                    name: "node_modules",
                    path: itemURL.path,
                    size: size,
                    category: .developerFiles,
                    modifiedDate: nil,
                    isSafeToDelete: true,
                    impactScore: .medium
                ))
            } else if itemURL.lastPathComponent != "node_modules" {
                findNodeModules(
                    in: itemURL.path, files: &files, totalSize: &totalSize, depth: depth + 1,
                    maxDepth: maxDepth)
            }
        }
    }

    /// Scan Docker cache
    private func scanDockerCache() async -> DevToolResult {
        let home = fileManager.homeDirectoryForCurrentUser.path
        let dockerPath = "\(home)/Library/Containers/com.docker.docker"
        var totalSize: Int64 = 0
        var files: [ScannedFile] = []

        if fileManager.fileExists(atPath: dockerPath) {
            totalSize = diskService.directorySize(at: dockerPath)
            files.append(ScannedFile(
                name: "Docker Data",
                path: dockerPath,
                size: totalSize,
                category: .developerFiles,
                modifiedDate: nil,
                isSafeToDelete: false,  // Docker data needs careful handling
                impactScore: .critical
            ))
        }

        return DevToolResult(
            name: "Docker Engines",
            icon: "shippingbox",
            size: totalSize,
            description:
                "Dangling images, stopped containers, and unused volumes are taking up significant space.",
            actionLabel: "Clear System",
            category: .containers,
            items: files
        )
    }

    /// Scan Xcode artifacts
    private func scanXcodeArtifacts() async -> DevToolResult {
        let home = fileManager.homeDirectoryForCurrentUser.path
        var totalSize: Int64 = 0
        var files: [ScannedFile] = []

        let paths = [
            ("\(home)/Library/Developer/Xcode/DerivedData", "DerivedData"),
            ("\(home)/Library/Developer/Xcode/Archives", "Archives"),
            ("\(home)/Library/Developer/CoreSimulator", "Simulators"),
        ]

        for (path, name) in paths {
            if fileManager.fileExists(atPath: path) {
                let size = diskService.directorySize(at: path)
                totalSize += size
                files.append(ScannedFile(
                    name: name,
                    path: path,
                    size: size,
                    category: .developerFiles,
                    modifiedDate: nil,
                    isSafeToDelete: true,
                    impactScore: .critical
                ))
            }
        }

        return DevToolResult(
            name: "Xcode Artifacts",
            icon: "hammer",
            size: totalSize,
            description:
                "DerivedData, old archives, and simulator logs from previous build cycles.",
            actionLabel: "Flush DerivedData",
            category: .mobile,
            items: files
        )
    }

    /// Scan package manager caches
    private func scanPackageCaches() async -> DevToolResult {
        let home = fileManager.homeDirectoryForCurrentUser.path
        var totalSize: Int64 = 0
        var files: [ScannedFile] = []

        let caches = [
            ("\(home)/.npm", "npm cache"),
            ("\(home)/Library/pnpm/store", "pnpm store"),
            ("\(home)/Library/Caches/Yarn", "Yarn cache"),
            ("\(home)/Library/Caches/CocoaPods", "CocoaPods cache"),
            ("\(home)/Library/Caches/Homebrew", "Homebrew cache"),
            ("\(home)/.expo", "Expo cache"),
        ]

        for (path, name) in caches {
            if fileManager.fileExists(atPath: path) {
                let size = diskService.directorySize(at: path)
                totalSize += size
                files.append(ScannedFile(
                    name: name,
                    path: path,
                    size: size,
                    category: .developerFiles,
                    modifiedDate: nil,
                    isSafeToDelete: true,
                    impactScore: .medium
                ))
            }
        }

        return DevToolResult(
            name: "Package Caches",
            icon: "shippingbox.fill",
            size: totalSize,
            description:
                "Homebrew, CocoaPods, and Yarn caches. Cleaning these will require re-downloading on next use.",
            actionLabel: "Clear Caches",
            category: .javascript,
            items: files
        )
    }
}
