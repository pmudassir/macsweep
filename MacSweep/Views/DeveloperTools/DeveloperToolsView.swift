import SwiftUI

// MARK: - Developer Tools View (Matches Stitch Screen 4)

struct DeveloperToolsView: View {
    @StateObject private var viewModel = DeveloperToolsViewModel()

    var body: some View {
        HStack(spacing: 0) {
            devSidebar
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xxl) {
                    headerSection
                    tabsSection
                    devToolCardsGrid
                    optimizationImpact
                }
                .padding(Theme.Spacing.xxxl)
            }
        }
        .background(Theme.Colors.background)
        .task { await viewModel.scanDevTools() }
    }

    private var devSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("MAIN").font(Theme.Typography.overline)
                    .foregroundColor(Theme.Colors.tertiaryText)
                    .padding(.horizontal, Theme.Spacing.lg).padding(.top, Theme.Spacing.xl).tracking(1)
                sidebarItem(icon: "square.grid.2x2", label: "Overview", active: false)
                sidebarItem(icon: "trash", label: "System Cleanup", active: false)
                sidebarItem(icon: "terminal", label: "Developer Mode", active: true)
            }
            Spacer().frame(height: Theme.Spacing.xxl)
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("ANALYSIS").font(Theme.Typography.overline)
                    .foregroundColor(Theme.Colors.tertiaryText)
                    .padding(.horizontal, Theme.Spacing.lg).tracking(1)
                sidebarItem(icon: "doc.fill", label: "Large Files", active: false)
                sidebarItem(icon: "clock.arrow.circlepath", label: "History", active: false)
            }
            Spacer()
            proAccountCard
        }
        .frame(width: 220)
        .background(Theme.Colors.sidebarBackground)
        .overlay(Divider().background(Theme.Colors.border), alignment: .trailing)
    }

    private func sidebarItem(icon: String, label: String, active: Bool) -> some View {
        let color = active ? Theme.Colors.secondaryAccent : Theme.Colors.secondaryText
        return HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon).font(.system(size: 14)).frame(width: 20)
            Text(label).font(Theme.Typography.body)
        }
        .foregroundColor(color)
        .padding(.horizontal, Theme.Spacing.lg).padding(.vertical, Theme.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(active ? color.opacity(0.15) : Color.clear)
        .cornerRadius(Theme.Radius.medium)
        .padding(.horizontal, Theme.Spacing.sm)
    }

    private var proAccountCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "checkmark.seal.fill").foregroundColor(Theme.Colors.secondaryAccent)
                Text("Pro Account").font(Theme.Typography.headline).foregroundColor(Theme.Colors.primaryText)
            }
            Text("You have reclaimed 124GB this month.")
                .font(Theme.Typography.caption).foregroundColor(Theme.Colors.secondaryText)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(Theme.Colors.border).frame(height: 4)
                    RoundedRectangle(cornerRadius: 2).fill(Theme.Colors.primaryAccent)
                        .frame(width: geo.size.width * 0.7, height: 4)
                }
            }.frame(height: 4)
        }
        .padding(Theme.Spacing.lg).cardStyle().padding(Theme.Spacing.lg)
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Developer Tools").font(Theme.Typography.largeTitle).foregroundColor(Theme.Colors.primaryText)
                Text("Manage development artifacts and reclaim storage from local environments.")
                    .font(Theme.Typography.body).foregroundColor(Theme.Colors.secondaryText)
            }
            Spacer()
            Button(action: {
                Task { for r in viewModel.devResults { await viewModel.cleanDevTool(r) } }
            }) {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "arrow.down.doc")
                    Text("Clean All Dev Files").font(Theme.Typography.headline)
                }.padding(.horizontal, Theme.Spacing.xl).padding(.vertical, Theme.Spacing.md)
                .background(Theme.Colors.elevatedBackground).foregroundColor(Theme.Colors.primaryText)
                .cornerRadius(Theme.Radius.medium)
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.medium).stroke(Theme.Colors.border, lineWidth: 1))
            }.buttonStyle(.plain)
        }
    }

    private var tabsSection: some View {
        HStack(spacing: Theme.Spacing.xl) {
            ForEach(viewModel.tabs, id: \.self) { tab in
                Button(action: { viewModel.activeTab = tab }) {
                    Text(tab).font(Theme.Typography.body)
                        .foregroundColor(viewModel.activeTab == tab ? Theme.Colors.secondaryAccent : Theme.Colors.secondaryText)
                        .padding(.bottom, Theme.Spacing.sm)
                        .overlay(viewModel.activeTab == tab ?
                            Rectangle().fill(Theme.Colors.secondaryAccent).frame(height: 2).offset(y: Theme.Spacing.sm)
                            : nil, alignment: .bottom)
                }.buttonStyle(.plain)
            }
        }
    }

    private var devToolCardsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: Theme.Spacing.lg), GridItem(.flexible(), spacing: Theme.Spacing.lg)], spacing: Theme.Spacing.lg) {
            ForEach(viewModel.filteredResults) { result in
                DevToolCard(result: result, onClean: { Task { await viewModel.cleanDevTool(result) } })
            }
        }
    }

    private var optimizationImpact: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Text("OPTIMIZATION IMPACT").font(Theme.Typography.overline)
                .foregroundColor(Theme.Colors.secondaryAccent).tracking(1.5)
            HStack(spacing: Theme.Spacing.xxxl) {
                impactStat(value: FileSize(viewModel.totalReclaimable).shortFormatted, label: "Total Potentially Reclaimable", color: Theme.Colors.primaryText)
                impactStat(value: "1.2x", label: "Estimated SSD Speed Increase", color: Theme.Colors.secondaryAccent)
                impactStat(value: "\(viewModel.devResults.count)", label: "Environment Types Managed", color: Theme.Colors.primaryText)
            }
        }.padding(Theme.Spacing.xxl).frame(maxWidth: .infinity, alignment: .leading).cardStyle()
    }

    private func impactStat(value: String, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(value).font(Theme.Typography.metric).foregroundColor(color)
            Text(label).font(Theme.Typography.caption).foregroundColor(Theme.Colors.secondaryText)
        }
    }
}

// MARK: - Dev Tool Card
struct DevToolCard: View {
    let result: DevToolResult
    let onClean: () -> Void
    @State private var showConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            HStack {
                Image(systemName: result.icon).font(.system(size: 18))
                    .foregroundColor(Theme.Colors.secondaryAccent)
                    .frame(width: 40, height: 40)
                    .background(Theme.Colors.secondaryAccent.opacity(0.15))
                    .cornerRadius(Theme.Radius.medium)
                Spacer()
                VStack(alignment: .trailing, spacing: Theme.Spacing.xs) {
                    Text(result.formattedSize).font(Theme.Typography.title).foregroundColor(Theme.Colors.secondaryAccent)
                    Text("FOUND").font(Theme.Typography.overline).foregroundColor(Theme.Colors.secondaryText).tracking(1)
                }
            }
            Text(result.name).font(Theme.Typography.title2).foregroundColor(Theme.Colors.primaryText)
            Text(result.description).font(Theme.Typography.caption).foregroundColor(Theme.Colors.secondaryText).lineLimit(2)
            HStack(spacing: Theme.Spacing.md) {
                Button(action: { showConfirm = true }) {
                    Text(result.actionLabel).font(Theme.Typography.headline).frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(Theme.Colors.secondaryAccent).foregroundColor(Theme.Colors.background)
                        .cornerRadius(Theme.Radius.medium)
                }.buttonStyle(.plain)
                Button(action: {}) {
                    Image(systemName: "gearshape").font(.system(size: 16)).foregroundColor(Theme.Colors.secondaryText)
                        .frame(width: 40, height: 40).background(Theme.Colors.elevatedBackground)
                        .cornerRadius(Theme.Radius.medium)
                        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.medium).stroke(Theme.Colors.border, lineWidth: 1))
                }.buttonStyle(.plain)
            }
        }
        .padding(Theme.Spacing.xl).cardStyle()
        .alert("Clean \(result.name)?", isPresented: $showConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Clean", role: .destructive, action: onClean)
        } message: { Text("This will remove \(result.formattedSize). Files can be rebuilt.") }
    }
}
