import SwiftUI

// MARK: - Navigation

enum NavigationItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case smartScan = "Smart Scan"
    case developerTools = "Developer Tools"
    case appManager = "App Manager"
    case caches = "Caches"
    case largeFiles = "Large Files"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .smartScan: return "wand.and.stars"
        case .developerTools: return "terminal"
        case .appManager: return "app.badge"
        case .caches: return "cylinder.split.1x2"
        case .largeFiles: return "doc.on.doc"
        case .settings: return "gearshape"
        }
    }

    var section: String? {
        switch self {
        case .caches, .largeFiles: return "SYSTEM UTILITIES"
        default: return nil
        }
    }
}

// MARK: - Content View (Main Shell)

struct ContentView: View {
    @State private var selectedItem: NavigationItem = .dashboard
    @AppStorage("developerMode") private var developerMode = false

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
        }
        .frame(minWidth: 1100, minHeight: 700)
        .background(Theme.Colors.background)
    }

    // MARK: - Sidebar
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // App Logo
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: "arrow.down.doc.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.Colors.primaryAccent)
                    .frame(width: 32, height: 32)
                    .background(Theme.Colors.primaryAccent.opacity(0.2))
                    .cornerRadius(Theme.Radius.medium)
                Text("MacSweep")
                    .font(Theme.Typography.title2)
                    .foregroundColor(Theme.Colors.primaryText)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.xl)

            // Main nav items
            ForEach(mainItems) { item in
                navButton(item)
            }

            // System Utilities section
            Text("SYSTEM UTILITIES")
                .font(Theme.Typography.overline)
                .foregroundColor(Theme.Colors.tertiaryText)
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.xl)
                .padding(.bottom, Theme.Spacing.sm)
                .tracking(1)

            ForEach(utilityItems) { item in
                navButton(item)
            }

            Spacer()

            // Pro upsell
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("PRO PLAN")
                    .font(Theme.Typography.overline)
                    .foregroundColor(Theme.Colors.secondaryAccent)
                    .tracking(1)
                Text("Get advanced developer tools")
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.primaryText)
                Button("Upgrade Now") {}
                    .font(Theme.Typography.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(Theme.Colors.secondaryAccent)
                    .foregroundColor(Theme.Colors.background)
                    .cornerRadius(Theme.Radius.medium)
                    .buttonStyle(.plain)
            }
            .padding(Theme.Spacing.lg)
            .background(Theme.Colors.secondaryAccent.opacity(0.1))
            .cornerRadius(Theme.Radius.medium)
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.medium).stroke(Theme.Colors.secondaryAccent.opacity(0.3), lineWidth: 1))
            .padding(Theme.Spacing.lg)

            // Settings
            navButton(.settings)
                .padding(.bottom, Theme.Spacing.md)
        }
        .frame(width: 220)
        .background(Theme.Colors.sidebarBackground)
        .scrollContentBackground(.hidden)
    }

    private var mainItems: [NavigationItem] {
        var items: [NavigationItem] = [.dashboard, .smartScan]
        if developerMode { items.append(.developerTools) }
        items.append(.appManager)
        return items
    }

    private var utilityItems: [NavigationItem] {
        [.caches, .largeFiles]
    }

    private func navButton(_ item: NavigationItem) -> some View {
        Button(action: { selectedItem = item }) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: item.icon).font(.system(size: 14)).frame(width: 20)
                Text(item.rawValue).font(Theme.Typography.body)
            }
            .foregroundColor(selectedItem == item ? Theme.Colors.primaryAccent : Theme.Colors.secondaryText)
            .padding(.horizontal, Theme.Spacing.lg).padding(.vertical, Theme.Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(selectedItem == item ? Theme.Colors.primaryAccent.opacity(0.12) : Color.clear)
            .cornerRadius(Theme.Radius.medium)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Theme.Spacing.sm)
    }

    // MARK: - Detail View
    @ViewBuilder
    private var detailView: some View {
        switch selectedItem {
        case .dashboard:
            DashboardView()
        case .smartScan, .caches:
            ScanResultsView()
        case .developerTools:
            DeveloperToolsView()
        case .appManager, .largeFiles:
            CleanupManagerView()
        case .settings:
            SettingsView()
        }
    }
}
