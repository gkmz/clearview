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
    var backgroundImageOpacity: Double
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
        backgroundImageOpacity: 1.0,
        mainWindowOpacity: 0.80,
        reminderWindowOpacity: 0.78
    )

    enum CodingKeys: String, CodingKey {
        case reminderEnabled
        case workIntervalMinutes
        case breakDurationSeconds
        case filterLevelKey
        case useBackgroundImage
        case playBreakFinishedSound
        case shortcutKeyCode
        case shortcutModifierFlagsRaw
        case backgroundImageOpacity
        case mainWindowOpacity
        case reminderWindowOpacity
    }

    init(
        reminderEnabled: Bool,
        workIntervalMinutes: Int,
        breakDurationSeconds: Int,
        filterLevelKey: String,
        useBackgroundImage: Bool,
        playBreakFinishedSound: Bool,
        shortcutKeyCode: UInt16,
        shortcutModifierFlagsRaw: UInt,
        backgroundImageOpacity: Double,
        mainWindowOpacity: Double,
        reminderWindowOpacity: Double
    ) {
        self.reminderEnabled = reminderEnabled
        self.workIntervalMinutes = workIntervalMinutes
        self.breakDurationSeconds = breakDurationSeconds
        self.filterLevelKey = filterLevelKey
        self.useBackgroundImage = useBackgroundImage
        self.playBreakFinishedSound = playBreakFinishedSound
        self.shortcutKeyCode = shortcutKeyCode
        self.shortcutModifierFlagsRaw = shortcutModifierFlagsRaw
        self.backgroundImageOpacity = backgroundImageOpacity
        self.mainWindowOpacity = mainWindowOpacity
        self.reminderWindowOpacity = reminderWindowOpacity
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = AppSettings.default
        reminderEnabled = try container.decodeIfPresent(Bool.self, forKey: .reminderEnabled) ?? defaults.reminderEnabled
        workIntervalMinutes = try container.decodeIfPresent(Int.self, forKey: .workIntervalMinutes) ?? defaults.workIntervalMinutes
        breakDurationSeconds = try container.decodeIfPresent(Int.self, forKey: .breakDurationSeconds) ?? defaults.breakDurationSeconds
        filterLevelKey = try container.decodeIfPresent(String.self, forKey: .filterLevelKey) ?? defaults.filterLevelKey
        useBackgroundImage = try container.decodeIfPresent(Bool.self, forKey: .useBackgroundImage) ?? defaults.useBackgroundImage
        playBreakFinishedSound = try container.decodeIfPresent(Bool.self, forKey: .playBreakFinishedSound) ?? defaults.playBreakFinishedSound
        shortcutKeyCode = try container.decodeIfPresent(UInt16.self, forKey: .shortcutKeyCode) ?? defaults.shortcutKeyCode
        shortcutModifierFlagsRaw = try container.decodeIfPresent(UInt.self, forKey: .shortcutModifierFlagsRaw) ?? defaults.shortcutModifierFlagsRaw
        backgroundImageOpacity = try container.decodeIfPresent(Double.self, forKey: .backgroundImageOpacity) ?? defaults.backgroundImageOpacity
        mainWindowOpacity = try container.decodeIfPresent(Double.self, forKey: .mainWindowOpacity) ?? defaults.mainWindowOpacity
        reminderWindowOpacity = try container.decodeIfPresent(Double.self, forKey: .reminderWindowOpacity) ?? defaults.reminderWindowOpacity
    }
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
