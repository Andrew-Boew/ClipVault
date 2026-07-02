import Foundation

enum SettingsKeys {
    static let maxItems = "maxHistoryItems"
    static let maxAgeDays = "maxHistoryAgeDays"
    static let excludedApps = "excludedApps"
    static let copyScreenshots = "copyScreenshotsToClipboard"
}

enum AppSettings {
    static var maxItems: Int {
        let value = UserDefaults.standard.integer(forKey: SettingsKeys.maxItems)
        return value > 0 ? value : 500
    }

    static var maxAgeDays: Int {
        let value = UserDefaults.standard.integer(forKey: SettingsKeys.maxAgeDays)
        return value > 0 ? value : 7
    }

    static var copyScreenshotsToClipboard: Bool {
        UserDefaults.standard.object(forKey: SettingsKeys.copyScreenshots) as? Bool ?? true
    }

    static var excludedApps: [String] {
        (UserDefaults.standard.string(forKey: SettingsKeys.excludedApps) ?? "")
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}
