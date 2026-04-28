import Foundation

struct AppSettings: Codable {
    var reminderEnabled: Bool
    var workIntervalMinutes: Int
    var breakDurationSeconds: Int
    var filterLevelKey: String
    var useBackgroundImage: Bool
    var playBreakFinishedSound: Bool
    var shortcutKeyCode: UInt16
    var shortcutModifierFlagsRaw: UInt
    var mainWindowOpacity: Double
    var reminderWindowOpacity: Double

    static let `default` = AppSettings(
        reminderEnabled: true,
        workIntervalMinutes: 20,
        breakDurationSeconds: 20,
        filterLevelKey: "off",
        useBackgroundImage: false,
        playBreakFinishedSound: false,
        // 关键流程：默认快捷键使用 Command + Shift + Space，便于单手快速唤起主界面。
        shortcutKeyCode: 49,
        shortcutModifierFlagsRaw: 1_179_648,
        mainWindowOpacity: 0.80,
        reminderWindowOpacity: 0.78
    )
}

final class AppSettingsStore {
    private let defaults: UserDefaults
    private let key = "clearview.app.settings.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> AppSettings {
        guard let data = defaults.data(forKey: key) else {
            return .default
        }

        do {
            return try JSONDecoder().decode(AppSettings.self, from: data)
        } catch {
            // 关键流程：配置损坏时回退默认值，避免影响应用启动。
            return .default
        }
    }

    func save(_ settings: AppSettings) {
        do {
            let data = try JSONEncoder().encode(settings)
            defaults.set(data, forKey: key)
        } catch {
            // 关键流程：写入失败时不打断主流程，保持当前内存状态可继续使用。
        }
    }
}

extension BlueLightLevel {
    var settingsKey: String {
        switch self {
        case .off: return "off"
        case .light: return "light"
        case .medium: return "medium"
        case .night: return "night"
        }
    }

    static func fromSettingsKey(_ key: String) -> BlueLightLevel {
        switch key {
        case "light": return .light
        case "medium": return .medium
        case "night": return .night
        default: return .off
        }
    }
}
