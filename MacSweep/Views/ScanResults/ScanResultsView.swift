import SwiftUI

// MARK: - Scan Results View (Matches Stitch Screen 2)

struct ScanResultsView: View {
    @StateObject private var viewModel = ScanResultsViewModel()
    @State private var showCleanAllConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xxl) {
                // Scan Status Header
                scanStatusHeader

                // Category Cards Grid
                categoryCardsGrid

                // Detailed Analysis
                detailedAnalysisSection

                // Footer
                footerSection
            }
            .padding(Theme.Spacing.xxxl)
        }
        .background(Theme.Colors.background)
        .task {
            if viewModel.scanResults.isEmpty {
                await viewModel.startScan()
            }
        }
        .alert("Clean All Files?", isPresented: $showCleanAllConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Clean All", role: .destructive) {
                Task { await viewModel.cleanAll() }
            }
        } message: {
            Text(
                "This will move \(FileSize(viewModel.totalCleanable).shortFormatted) of files to Trash. You can restore them from Trash if needed."
            )
        }
    }

    // MARK: - Scan Status Header
    private var scanStatusHeader: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            if viewModel.isScanning {
                HStack(spacing: Theme.Spacing.sm) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.primaryAccent))
                        .scaleEffect(0.8)
                    Text("SCANNING...")
                        .font(Theme.Typography.overline)
                        .foregroundColor(Theme.Colors.primaryAccent)
                        .tracking(1.5)
                }

                Text("Analyzing your system...")
                    .font(Theme.Typography.largeTitle)
                    .foregroundColor(Theme.Colors.primaryText)

                ProgressView(value: viewModel.scanProgress)
                    .tint(Theme.Colors.primaryAccent)
            } else {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.Colors.secondaryAccent)
                    Text("SCAN COMPLETE")
                        .font(Theme.Typography.overline)
                        .foregroundColor(Theme.Colors.secondaryAccent)
                        .tracking(1.5)
                }

                HStack {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("\(FileSize(viewModel.totalCleanable).shortFormatted) Ready to Clean")
                            .font(Theme.Typography.largeTitle)
                            .foregroundColor(Theme.Colors.primaryText)

                        Text(
                            "We've identified unnecessary system junk and developer artifacts that are safe to remove."
                        )
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.secondaryText)
                    }

                    Spacer()

                    HStack(spacing: Theme.Spacing.md) {
                        Button(action: {
                            Task { await viewModel.startScan() }
                        }) {
                            Text("Rescan")
                                .font(Theme.Typography.headline)
                                .padding(.horizontal, Theme.Spacing.xl)
                                .padding(.vertical, Theme.Spacing.md)
                                .background(Theme.Colors.elevatedBackground)
                                .foregroundColor(Theme.Colors.primaryText)
                                .cornerRadius(Theme.Radius.medium)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.Radius.medium)
                                        .stroke(Theme.Colors.border, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)

                        Button(action: { showCleanAllConfirm = true }) {
                            HStack(spacing: Theme.Spacing.sm) {
                                Image(systemName: "sparkles")
                                Text("Clean All Files")
                                    .font(Theme.Typography.headline)
                            }
                            .padding(.horizontal, Theme.Spacing.xl)
                            .padding(.vertical, Theme.Spacing.md)
                            .background(Theme.Colors.primaryAccent)
                            .foregroundColor(.white)
                            .cornerRadius(Theme.Radius.medium)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Category Cards Grid
    private var categoryCardsGrid: some View {
        let categories: [ScanCategory] = [
            .browserCaches, .systemLogs, .developerFiles, .downloads, .trashBin,
        ]

        return LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: Theme.Spacing.lg),
                GridItem(.flexible(), spacing: Theme.Spacing.lg),
                GridItem(.flexible(), spacing: Theme.Spacing.lg),
            ],
            spacing: Theme.Spacing.lg
        ) {
            ForEach(categories) { category in
                ScanCategoryCard(
                    category: category,
                    result: viewModel.scanResults[category],
                    onClean: {
                        Task { await viewModel.cleanCategory(category) }
                    }
                )
            }

            // Custom Path Card
            customPathCard
        }
    }

    private var customPathCard: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "plus")
                .font(.system(size: 24))
                .foregroundColor(Theme.Colors.secondaryText)

            Text("Custom Path")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.primaryText)

            Text("Scan a specific folder")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, minHeight: 180)
        .background(Color.clear)
        .cornerRadius(Theme.Radius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .stroke(Theme.Colors.border, style: StrokeStyle(lineWidth: 1, dash: [6]))
        )
    }

    // MARK: - Detailed Analysis
    private var detailedAnalysisSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "tablecells")
                    .foregroundColor(Theme.Colors.primaryAccent)
                Text("Detailed Analysis")
                    .font(Theme.Typography.title2)
                    .foregroundColor(Theme.Colors.primaryText)
            }

            // Table
            VStack(spacing: 0) {
                // Header row
                HStack {
                    Text("FILE SOURCE")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("IMPACT SCORE")
                        .frame(width: 120)
                    Text("STORAGE USED")
                        .frame(width: 120)
                    Text("ACTION")
                        .frame(width: 80)
                }
                .font(Theme.Typography.overline)
                .foregroundColor(Theme.Colors.tertiaryText)
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.vertical, Theme.Spacing.md)

                Divider().background(Theme.Colors.border)

                // Rows
                ForEach(topAnalysisItems) { file in
                    DetailedAnalysisRow(file: file)
                }
            }
            .cardStyle()
        }
    }

    private var topAnalysisItems: [ScannedFile] {
        viewModel.scanResults.values
            .flatMap { $0.files }
            .sorted { $0.size > $1.size }
            .prefix(5)
            .map { $0 }
    }

    // MARK: - Footer
    private var footerSection: some View {
        HStack {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "shield.checkered")
                    .foregroundColor(Theme.Colors.primaryAccent)
                Text("Securely analyzed locally on your Mac. No data ever leaves your device.")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
            }

            Spacer()

            HStack(spacing: Theme.Spacing.xl) {
                Text("Support").font(Theme.Typography.caption)
                Text("Documentation").font(Theme.Typography.caption)
                Text("Privacy").font(Theme.Typography.caption)
            }
            .foregroundColor(Theme.Colors.secondaryText)
        }
        .padding(.top, Theme.Spacing.xl)
    }
}

// MARK: - Scan Category Card
struct ScanCategoryCard: View {
    let category: ScanCategory
    let result: CategoryScanResult?
    let onClean: () -> Void
    @State private var showConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Image(systemName: category.icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .frame(width: 36, height: 36)
                .background(iconColor.opacity(0.15))
                .cornerRadius(Theme.Radius.medium)

            Text(category.displayName)
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.primaryText)

            Text(category.description)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.secondaryText)
                .lineLimit(2)

            Text(result?.formattedSize ?? "0 B")
                .font(Theme.Typography.title)
                .foregroundColor(Theme.Colors.secondaryAccent)

            Button(action: { showConfirm = true }) {
                Text("Clean")
                    .font(Theme.Typography.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.md)
                    .background(Theme.Colors.primaryAccent.opacity(0.15))
                    .foregroundColor(Theme.Colors.primaryAccent)
                    .cornerRadius(Theme.Radius.medium)
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .alert("Clean \(category.displayName)?", isPresented: $showConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Clean", role: .destructive, action: onClean)
        } message: {
            Text(
                "This will move \(result?.formattedSize ?? "0 B") to Trash. You can restore from Trash if needed."
            )
        }
    }

    private var iconColor: Color {
        switch category {
        case .browserCaches: return Theme.Colors.primaryAccent
        case .systemLogs: return Theme.Colors.warningAccent
        case .developerFiles: return Theme.Colors.orangeAccent
        case .downloads: return Theme.Colors.secondaryAccent
        case .trashBin: return Theme.Colors.dangerAccent
        default: return Theme.Colors.primaryAccent
        }
    }
}

// MARK: - Detailed Analysis Row
struct DetailedAnalysisRow: View {
    let file: ScannedFile

    var body: some View {
        HStack {
            // File source
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: file.category.icon)
                    .foregroundColor(Theme.Colors.primaryAccent)
                    .frame(width: 20)
                Text(file.locationDisplayPath)
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.primaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Impact
            Text(file.impactScore.displayName)
                .font(Theme.Typography.caption)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, 2)
                .background(Color(hex: file.impactScore.color).opacity(0.2))
                .foregroundColor(Color(hex: file.impactScore.color))
                .cornerRadius(Theme.Radius.small)
                .frame(width: 120)

            // Size
            Text(file.formattedSize)
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.primaryText)
                .frame(width: 120)

            // Action
            Text("Review")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.primaryAccent)
                .frame(width: 80)
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .padding(.vertical, Theme.Spacing.md)

        Divider().background(Theme.Colors.border)
    }
}
