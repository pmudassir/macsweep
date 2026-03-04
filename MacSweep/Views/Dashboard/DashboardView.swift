import SwiftUI

// MARK: - Dashboard View (Matches Stitch Screen 1)

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xxl) {
                // Header
                headerSection

                // Storage Stats Cards
                storageStatsSection

                // Disk Usage Chart
                diskChartSection

                // Category Cards
                categoryCardsSection
            }
            .padding(Theme.Spacing.xxxl)
        }
        .background(Theme.Colors.background)
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("System Overview")
                    .font(Theme.Typography.largeTitle)
                    .foregroundColor(Theme.Colors.primaryText)

                Text(lastScanText)
                    .font(Theme.Typography.callout)
                    .foregroundColor(Theme.Colors.secondaryText)
            }

            Spacer()

            Button(action: {
                Task { await viewModel.loadData() }
            }) {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                    Text("Scan System")
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

    // MARK: - Storage Stats
    private var storageStatsSection: some View {
        HStack(spacing: Theme.Spacing.lg) {
            StorageCard(
                title: "Total Storage",
                value: viewModel.diskUsage.formattedTotal,
                color: Theme.Colors.primaryText,
                progressColor: Theme.Colors.secondaryText,
                progress: 1.0
            )

            StorageCard(
                title: "Used Space",
                value: viewModel.diskUsage.formattedUsed,
                color: Theme.Colors.primaryAccent,
                progressColor: Theme.Colors.primaryAccent,
                progress: viewModel.diskUsage.percentUsed / 100
            )

            StorageCard(
                title: "Free Space",
                value: viewModel.diskUsage.formattedFree,
                color: Theme.Colors.secondaryAccent,
                progressColor: Theme.Colors.secondaryAccent,
                progress: viewModel.diskUsage.percentFree / 100
            )
        }
    }

    // MARK: - Disk Chart
    private var diskChartSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Legend top
            HStack {
                Spacer()
                HStack(spacing: Theme.Spacing.sm) {
                    Circle()
                        .fill(Theme.Colors.primaryAccent)
                        .frame(width: 8, height: 8)
                    Text("Apps & System")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.primaryText)
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(Theme.Colors.elevatedBackground)
                .cornerRadius(Theme.Radius.large)
            }

            DiskChart(
                percentUsed: viewModel.diskUsage.percentUsed
            )

            // Legend bottom
            HStack(spacing: Theme.Spacing.sm) {
                Circle()
                    .fill(Theme.Colors.secondaryAccent)
                    .frame(width: 8, height: 8)
                Text("Free Space")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.primaryText)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(Theme.Colors.elevatedBackground)
            .cornerRadius(Theme.Radius.large)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xl)
    }

    // MARK: - Category Cards
    private var categoryCardsSection: some View {
        HStack(spacing: Theme.Spacing.lg) {
            ForEach(viewModel.storageCategories) { category in
                CategoryInfoCard(category: category)
            }
        }
    }

    private var lastScanText: String {
        guard let lastScan = viewModel.lastScanTime else {
            return "No scans performed yet"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "Last scan performed \(formatter.localizedString(for: lastScan, relativeTo: Date()))"
    }
}

// MARK: - Storage Card Component
struct StorageCard: View {
    let title: String
    let value: String
    let color: Color
    let progressColor: Color
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text(title)
                .font(Theme.Typography.callout)
                .foregroundColor(Theme.Colors.secondaryText)

            Text(value)
                .font(Theme.Typography.title)
                .foregroundColor(color)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.Colors.border)
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(progressColor)
                        .frame(width: geo.size.width * max(0, min(progress, 1)), height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

// MARK: - Category Info Card
struct CategoryInfoCard: View {
    let category: StorageCategoryInfo

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Image(systemName: category.icon)
                .font(.system(size: 18))
                .foregroundColor(Color(hex: category.color))
                .frame(width: 36, height: 36)
                .background(Color(hex: category.color).opacity(0.15))
                .cornerRadius(Theme.Radius.medium)

            Text(category.name)
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.primaryText)

            Text(category.formattedSize)
                .font(Theme.Typography.callout)
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

// MARK: - Disk Chart Component
struct DiskChart: View {
    let percentUsed: Double

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Theme.Colors.border, lineWidth: 20)
                .frame(width: 220, height: 220)

            // Used space arc
            Circle()
                .trim(from: 0, to: CGFloat(percentUsed / 100))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Theme.Colors.chartGradientStart,
                            Theme.Colors.chartGradientEnd,
                            Theme.Colors.chartGradientStart,
                        ]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 220, height: 220)
                .animation(.easeInOut(duration: 1.0), value: percentUsed)

            // Center text
            VStack(spacing: Theme.Spacing.xs) {
                Text("\(Int(percentUsed))%")
                    .font(Theme.Typography.metricLarge)
                    .foregroundColor(Theme.Colors.primaryText)

                Text("DISK USED")
                    .font(Theme.Typography.overline)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .tracking(1.5)
            }
        }
        .frame(width: 260, height: 260)
    }
}
