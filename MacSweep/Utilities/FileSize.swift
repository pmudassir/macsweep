import Foundation

// MARK: - Human-readable file size formatting

struct FileSize {
    let bytes: Int64

    init(_ bytes: Int64) {
        self.bytes = bytes
    }

    init(_ bytes: UInt64) {
        self.bytes = Int64(bytes)
    }

    init(_ bytes: Int) {
        self.bytes = Int64(bytes)
    }

    var formatted: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter.string(fromByteCount: bytes)
    }

    var shortFormatted: String {
        let absBytes = abs(Double(bytes))
        let units: [(String, Double)] = [
            ("TB", 1_099_511_627_776),
            ("GB", 1_073_741_824),
            ("MB", 1_048_576),
            ("KB", 1_024),
        ]

        for (unit, threshold) in units {
            if absBytes >= threshold {
                let value = Double(bytes) / threshold
                if value == Double(Int(value)) {
                    return "\(Int(value)) \(unit)"
                }
                return String(format: "%.1f \(unit)", value)
            }
        }

        return "\(bytes) B"
    }

    // Numeric value in the most appropriate unit
    var numericValue: Double {
        let absBytes = abs(Double(bytes))
        if absBytes >= 1_099_511_627_776 { return Double(bytes) / 1_099_511_627_776 }
        if absBytes >= 1_073_741_824 { return Double(bytes) / 1_073_741_824 }
        if absBytes >= 1_048_576 { return Double(bytes) / 1_048_576 }
        if absBytes >= 1_024 { return Double(bytes) / 1_024 }
        return Double(bytes)
    }

    var unit: String {
        let absBytes = abs(Double(bytes))
        if absBytes >= 1_099_511_627_776 { return "TB" }
        if absBytes >= 1_073_741_824 { return "GB" }
        if absBytes >= 1_048_576 { return "MB" }
        if absBytes >= 1_024 { return "KB" }
        return "B"
    }
}

extension Int64 {
    var fileSize: FileSize {
        FileSize(self)
    }
}
