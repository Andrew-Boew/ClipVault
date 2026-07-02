import SwiftUI
import ServiceManagement
import KeyboardShortcuts

struct SettingsView: View {
    @AppStorage(SettingsKeys.maxItems) private var maxItems = 500
    @AppStorage(SettingsKeys.maxAgeDays) private var maxAgeDays = 7
    @AppStorage(SettingsKeys.excludedApps) private var excludedAppsRaw = ""
    @AppStorage(SettingsKeys.copyScreenshots) private var copyScreenshots = true

    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    private var excludedApps: [String] {
        excludedAppsRaw
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        Form {
            Section("Hotkey") {
                KeyboardShortcuts.Recorder("Show history:", name: .toggleHistory)
            }

            Section("History limits") {
                Stepper("Max items: \(maxItems)", value: $maxItems, in: 50...5000, step: 50)
                Stepper("Delete after: \(maxAgeDays) days", value: $maxAgeDays, in: 1...365)
            }

            Section("Excluded apps") {
                if excludedApps.isEmpty {
                    Text("History is recorded from all apps")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(excludedApps, id: \.self) { app in
                        HStack {
                            Text(app)
                            Spacer()
                            Button(role: .destructive) {
                                removeExcludedApp(app)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.red)
                        }
                    }
                }

                Menu("Add running app…") {
                    ForEach(runningAppNames, id: \.self) { name in
                        Button(name) {
                            addExcludedApp(name)
                        }
                    }
                }
            }

            Section("About") {
                LabeledContent("Version", value: appVersion)
                LabeledContent("Storage", value: "Local only — nothing leaves your Mac")
            }

            Section {
                Toggle("Copy new screenshots to clipboard", isOn: $copyScreenshots)
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) {
                        updateLaunchAtLogin()
                    }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 480)
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private var runningAppNames: [String] {
        NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap(\.localizedName)
            .filter { !excludedApps.contains($0) }
            .sorted()
    }

    private func addExcludedApp(_ name: String) {
        excludedAppsRaw = (excludedApps + [name]).joined(separator: "\n")
    }

    private func removeExcludedApp(_ name: String) {
        excludedAppsRaw = excludedApps.filter { $0 != name }.joined(separator: "\n")
    }

    private func updateLaunchAtLogin() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
