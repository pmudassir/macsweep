import SwiftUI

// MARK: - Cleanup Manager View (Matches Stitch Screen 3)

struct CleanupManagerView: View {
    @StateObject private var viewModel = CleanupViewModel()
    @State private var showBulkDeleteConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbarSection

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xxl) {
                    // Header
                    headerSection

                    // Tabs
                    tabsSection

                    // File Table
                    fileTableSection

                    // Summary Cards
                    summaryCardsSection

                    // Optimization Recommendation
                    recommendationBanner

                    // Footer
                    footerSection
                }
                .padding(Theme.Spacing.xxxl)
            }
        }
        .background(Theme.Colors.background)
        .task {
            await viewModel.loadFiles()
        }
        .alert("Delete Selected Files?", isPresented: $showBulkDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task { await viewModel.deleteSelected() }
            }
        } message: {
            Text(
                "This will move \(viewModel.selectedCount) files (\(FileSize(viewModel.selectedSize).shortFormatted)) to Trash."
            )
        }
    }

    // MARK: - Toolbar
    private var toolbarSection: some View {
        HStack(spacing: Theme.Spacing.lg) {
            // Search
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.Colors.secondaryText)
                TextField("Quick find files...", text: $viewModel.searchQuery)
                    .textFieldStyle(.plain)
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.primaryText)

                Text("⌘K")
                    .font(Theme.Typography.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.Colors.elevatedBackground)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .cornerRadius(4)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(Theme.Colors.elevatedBackground)
            .cornerRadius(Theme.Radius.medium)
            .frame(maxWidth: 300)

            Spacer()

            // Action buttons
            Button(action: { showBulkDeleteConfirm = true }) {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "trash.fill")
                    Text("Bulk Delete")
                        .font(Theme.Typography.headline)
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.sm)
                .background(Theme.Colors.dangerAccent)
                .foregroundColor(.white)
                .cornerRadius(Theme.Radius.medium)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.selectedFiles.isEmpty)

            Button(action: {}) {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "eye")
                    Text("Preview")
                        .font(Theme.Typography.headline)
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.sm)
                .background(Theme.Colors.elevatedBackground)
                .foregroundColor(Theme.Colors.primaryText)
                .cornerRadius(Theme.Radius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.medium)
                        .stroke(Theme.Colors.border, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.Spacing.xxxl)
        .padding(.vertical, Theme.Spacing.md)
        .background(Theme.Colors.headerBackground)
        .overlay(
            Divider().background(Theme.Colors.border),
            alignment: .bottom
        )
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .foregroundColor(Theme.Colors.primaryAccent)
                    Text("System Maintenance")
                        .font(Theme.Typography.overline)
                        .foregroundColor(Theme.Colors.primaryAccent)
                        .tracking(1)
                }

                Text("Cleanup Manager")
                    .font(Theme.Typography.largeTitle)
                    .foregroundColor(Theme.Colors.primaryText)

                Text(
                    "Reclaim your storage by purging deep system junk, legacy logs, and redundant developer artifacts."
                )
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.secondaryText)
            }

            Spacer()

            // Stats box
            HStack(spacing: Theme.Spacing.xxl) {
                VStack(spacing: Theme.Spacing.xs) {
                    Text("POTENTIAL GAIN")
                        .font(Theme.Typography.overline)
                        .foregroundColor(Theme.Colors.secondaryText)
                    Text(
                        FileSize(
                            viewModel.allFiles.reduce(0) { $0 + $1.size }
                        ).shortFormatted
                    )
                    .font(Theme.Typography.title)
                    .foregroundColor(Theme.Colors.secondaryAccent)
                }
                VStack(spacing: Theme.Spacing.xs) {
                    Text("ITEMS FOUND")
                        .font(Theme.Typography.overline)
                        .foregroundColor(Theme.Colors.secondaryText)
                    Text("\(viewModel.allFiles.count)")
                        .font(Theme.Typography.title)
                        .foregroundColor(Theme.Colors.primaryText)
                }
            }
            .padding(Theme.Spacing.xl)
            .cardStyle()
        }
    }

    // MARK: - Tabs
    private var tabsSection: some View {
        HStack(spacing: Theme.Spacing.xl) {
            ForEach(viewModel.tabs, id: \.self) { tab in
                Button(action: { viewModel.activeTab = tab }) {
                    Text(tab)
                        .font(Theme.Typography.body)
                        .foregroundColor(
                            viewModel.activeTab == tab
                                ? Theme.Colors.primaryAccent
                                : Theme.Colors.secondaryText
                        )
                        .padding(.bottom, Theme.Spacing.sm)
                        .overlay(
                            viewModel.activeTab == tab
                                ? Rectangle()
                                    .fill(Theme.Colors.primaryAccent)
                                    .frame(height: 2)
                                    .offset(y: Theme.Spacing.sm)
                                : nil,
                            alignment: .bottom
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - File Table
    private var fileTableSection: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "square")
                    .foregroundColor(Theme.Colors.secondaryText)
                    .frame(width: 30)
                    .onTapGesture {
                        if viewModel.selectedFiles.isEmpty {
                            viewModel.selectAll()
                        } else {
                            viewModel.deselectAll()
                        }
                    }

                Text("FILE NAME")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("LOCATION")
                    .frame(width: 220, alignment: .leading)
                Text("SIZE")
                    .frame(width: 100)
                Text("CATEGORY")
                    .frame(width: 100)
                Text("ACTIONS")
                    .frame(width: 60)
            }
            .font(Theme.Typography.overline)
            .foregroundColor(Theme.Colors.tertiaryText)
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.vertical, Theme.Spacing.md)

            Divider().background(Theme.Colors.border)

            // Rows
            ForEach(viewModel.filteredFiles.prefix(20)) { file in
                FileRow(
                    file: file,
                    isSelected: viewModel.selectedFiles.contains(file.id),
                    onToggle: { viewModel.toggleSelection(file) }
                )
            }

            if viewModel.filteredFiles.isEmpty {
                VStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "tray")
                        .font(.system(size: 32))
                        .foregroundColor(Theme.Colors.secondaryText)
                    Text("No files found in this category")
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.xxxl)
            }
        }
        .cardStyle()
    }

    // MARK: - Summary Cards
    private var summaryCardsSection: some View {
        HStack(spacing: Theme.Spacing.lg) {
            // Total Selected
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Total Selected")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                    Text(FileSize(viewModel.selectedSize).shortFormatted)
                        .font(Theme.Typography.title)
                        .foregroundColor(Theme.Colors.primaryText)
                }
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Theme.Colors.secondaryAccent)
                    .font(.system(size: 24))
            }
            .padding(Theme.Spacing.xl)
            .frame(maxWidth: .infinity)
            .cardStyle()

            // Storage Gain
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Storage Gain")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                    Text(
                        "+\(String(format: "%.0f", viewModel.storageGainPercent))%"
                    )
                    .font(Theme.Typography.title)
                    .foregroundColor(Theme.Colors.secondaryAccent)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .foregroundColor(Theme.Colors.secondaryAccent)
                    .font(.system(size: 24))
            }
            .padding(Theme.Spacing.xl)
            .frame(maxWidth: .infinity)
            .cardStyle()

            // Files to Remove
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Files to Remove")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                    Text("\(viewModel.selectedCount) files")
                        .font(Theme.Typography.title)
                        .foregroundColor(Theme.Colors.primaryText)
                }
                Spacer()
                Image(systemName: "trash")
                    .foregroundColor(Theme.Colors.secondaryText)
                    .font(.system(size: 24))
            }
            .padding(Theme.Spacing.xl)
            .frame(maxWidth: .infinity)
            .cardStyle()
        }
    }

    // MARK: - Recommendation Banner
    private var recommendationBanner: some View {
        HStack {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(Theme.Colors.primaryAccent)
                    .font(.system(size: 20))

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Optimization Recommendation")
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.primaryText)
                    Text(
                        "You have \(FileSize(viewModel.allFiles.filter { $0.isSafeToDelete }.reduce(0) { $0 + $1.size }).shortFormatted) of temporary assets that haven't been accessed in over 90 days."
                    )
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.secondaryText)
                }
            }

            Spacer()

            Button(action: {
                viewModel.selectAll()
            }) {
                Text("Resolve All")
                    .font(Theme.Typography.headline)
                    .padding(.horizontal, Theme.Spacing.xl)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(Theme.Colors.dangerAccent)
                    .foregroundColor(.white)
                    .cornerRadius(Theme.Radius.medium)
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.Spacing.xl)
        .background(Theme.Colors.primaryAccent.opacity(0.1))
        .cornerRadius(Theme.Radius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.medium)
                .stroke(Theme.Colors.primaryAccent.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Footer
    private var footerSection: some View {
        HStack {
            Text("MacSweep Engine v\(Constants.appVersion)")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.tertiaryText)

            Text("Last scan: 2 minutes ago")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.tertiaryText)

            Spacer()

            HStack(spacing: Theme.Spacing.xl) {
                Text("Documentation")
                Text("Support")
                Text("Preferences")
            }
            .font(Theme.Typography.caption)
            .foregroundColor(Theme.Colors.secondaryText)
        }
    }
}

// MARK: - File Row
struct FileRow: View {
    let file: ScannedFile
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack {
            // Checkbox
            Image(
                systemName: isSelected ? "checkmark.square.fill" : "square"
            )
            .foregroundColor(isSelected ? Theme.Colors.primaryAccent : Theme.Colors.secondaryText)
            .frame(width: 30)
            .onTapGesture(perform: onToggle)

            // Name + icon
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: file.category.icon)
                    .foregroundColor(categoryColor)
                    .frame(width: 24, height: 24)
                    .background(categoryColor.opacity(0.15))
                    .cornerRadius(4)

                Text(file.name)
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.primaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Location
            Text(file.locationDisplayPath)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.secondaryText)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, 2)
                .background(Theme.Colors.elevatedBackground)
                .cornerRadius(Theme.Radius.small)
                .lineLimit(1)
                .frame(width: 220, alignment: .leading)

            // Size
            Text(file.formattedSize)
                .font(Theme.Typography.body)
                .fontWeight(.medium)
                .foregroundColor(Theme.Colors.primaryText)
                .frame(width: 100)

            // Category badge
            Text(file.categoryLabel)
                .font(Theme.Typography.caption)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, 2)
                .background(categoryColor.opacity(0.15))
                .foregroundColor(categoryColor)
                .cornerRadius(Theme.Radius.small)
                .frame(width: 100)

            // Action
            Image(systemName: "arrow.up.forward.square")
                .foregroundColor(Theme.Colors.secondaryText)
                .frame(width: 60)
                .onTapGesture {
                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: file.path)
                }
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .padding(.vertical, Theme.Spacing.md)
        .background(
            isSelected ? Theme.Colors.primaryAccent.opacity(0.05) : Color.clear
        )

        Divider().background(Theme.Colors.border)
    }

    private var categoryColor: Color {
        switch file.categoryLabel {
        case "Developer": return Theme.Colors.secondaryAccent
        case "System": return Theme.Colors.primaryAccent
        case "Large Files": return Theme.Colors.orangeAccent
        default: return Theme.Colors.primaryAccent
        }
    }
}
