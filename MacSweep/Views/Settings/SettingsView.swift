import SwiftUI

// MARK: - Settings View (Matches Stitch Screen 5)

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        HStack(spacing: 0) {
            settingsSidebar
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xxl) {
                    Text("Settings").font(Theme.Typography.largeTitle).foregroundColor(Theme.Colors.primaryText)
                    Text("Manage your system cleaning preferences and automation.")
                        .font(Theme.Typography.body).foregroundColor(Theme.Colors.secondaryText)

                    // Cleaning Preferences
                    sectionHeader("CLEANING PREFERENCES")
                    VStack(spacing: 0) {
                        settingsToggle(icon: "chevron.left.forwardslash.chevron.right", iconColor: Theme.Colors.primaryAccent,
                            title: "Developer Mode", subtitle: "Clean SDKs, build artifacts, and derived data", isOn: $viewModel.developerMode)
                        Divider().background(Theme.Colors.border)
                        settingsToggle(icon: "arrow.clockwise", iconColor: Theme.Colors.secondaryAccent,
                            title: "Auto Scan", subtitle: "Periodically scan for junk files in background", isOn: $viewModel.autoScan)
                        Divider().background(Theme.Colors.border)
                        settingsToggle(icon: "bell.badge", iconColor: Theme.Colors.warningAccent,
                            title: "Weekly Cleanup Reminders", subtitle: "Get a notification to perform deep cleaning", isOn: $viewModel.weeklyReminders)
                    }.cardStyle()

                    // Advanced Options
                    sectionHeader("ADVANCED OPTIONS")
                    VStack(spacing: 0) {
                        settingsToggle(icon: "trash.fill", iconColor: Theme.Colors.dangerAccent,
                            title: "Auto-Empty Trash", subtitle: "Permanently delete items older than 30 days", isOn: $viewModel.autoEmptyTrash)
                        Divider().background(Theme.Colors.border)
                        settingsToggle(icon: "shield.checkered", iconColor: Theme.Colors.purpleAccent,
                            title: "Secure Erase", subtitle: "Overwrite files with random data before deletion", isOn: $viewModel.secureErase)
                    }.cardStyle()

                    // Action buttons
                    HStack(spacing: Theme.Spacing.lg) {
                        Spacer()
                        Button("Discard Changes") {
                            viewModel.discardChanges()
                        }
                        .font(Theme.Typography.headline)
                        .padding(.horizontal, Theme.Spacing.xl).padding(.vertical, Theme.Spacing.md)
                        .background(Theme.Colors.elevatedBackground).foregroundColor(Theme.Colors.primaryText)
                        .cornerRadius(Theme.Radius.medium)
                        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.medium).stroke(Theme.Colors.border, lineWidth: 1))
                        .buttonStyle(.plain)

                        Button("Save Preferences") {
                            viewModel.savePreferences()
                        }
                        .font(Theme.Typography.headline)
                        .padding(.horizontal, Theme.Spacing.xl).padding(.vertical, Theme.Spacing.md)
                        .background(Theme.Colors.dangerAccent).foregroundColor(.white)
                        .cornerRadius(Theme.Radius.medium)
                        .buttonStyle(.plain)
                    }
                }
                .padding(Theme.Spacing.xxxl)
            }
        }
        .background(Theme.Colors.background)
    }

    private var settingsSidebar: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            ForEach(viewModel.sections, id: \.self) { section in
                Button(action: { viewModel.activeSection = section }) {
                    HStack(spacing: Theme.Spacing.md) {
                        Image(systemName: sectionIcon(section)).font(.system(size: 14)).frame(width: 20)
                        Text(section).font(Theme.Typography.body)
                    }
                    .foregroundColor(viewModel.activeSection == section ? Theme.Colors.primaryAccent : Theme.Colors.secondaryText)
                    .padding(.horizontal, Theme.Spacing.lg).padding(.vertical, Theme.Spacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(viewModel.activeSection == section ? Theme.Colors.primaryAccent.opacity(0.15) : Color.clear)
                    .cornerRadius(Theme.Radius.medium)
                }.buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(Theme.Spacing.lg)
        .frame(width: 220)
        .background(Theme.Colors.sidebarBackground)
        .overlay(Divider().background(Theme.Colors.border), alignment: .trailing)
    }

    private func sectionIcon(_ section: String) -> String {
        switch section {
        case "General": return "gearshape"
        case "Developer": return "chevron.left.forwardslash.chevron.right"
        case "Scanning": return "magnifyingglass"
        case "Notifications": return "bell"
        case "About": return "info.circle"
        default: return "circle"
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title).font(Theme.Typography.overline).foregroundColor(Theme.Colors.tertiaryText).tracking(1.5)
    }

    private func settingsToggle(icon: String, iconColor: Color, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: Theme.Spacing.lg) {
            Image(systemName: icon).font(.system(size: 16)).foregroundColor(iconColor)
                .frame(width: 36, height: 36).background(iconColor.opacity(0.15)).cornerRadius(Theme.Radius.medium)
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(title).font(Theme.Typography.headline).foregroundColor(Theme.Colors.primaryText)
                Text(subtitle).font(Theme.Typography.caption).foregroundColor(Theme.Colors.secondaryText)
            }
            Spacer()
            Toggle("", isOn: isOn).toggleStyle(.switch).labelsHidden()
        }
        .padding(Theme.Spacing.xl)
    }
}
