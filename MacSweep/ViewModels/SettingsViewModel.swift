import Foundation
import SwiftUI

// MARK: - Settings ViewModel

@MainActor
class SettingsViewModel: ObservableObject {
    @AppStorage("developerMode") var developerMode = false
    @AppStorage("autoScan") var autoScan = false
    @AppStorage("weeklyReminders") var weeklyReminders = true
    @AppStorage("autoEmptyTrash") var autoEmptyTrash = false
    @AppStorage("secureErase") var secureErase = false
    @AppStorage("downloadAgeDays") var downloadAgeDays = 30

    @Published var activeSection = "General"
    @Published var hasChanges = false

    let sections = ["General", "Developer", "Scanning", "Notifications", "About"]

    func savePreferences() {
        hasChanges = false
    }

    func discardChanges() {
        hasChanges = false
    }
}
