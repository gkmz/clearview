import Foundation

struct ShortcutBinding: Codable, Equatable {
    var keyCode: UInt16
    var modifierFlagsRaw: UInt
}

enum ShortcutAction: String, CaseIterable, Codable {
    case toggleMainPanel
    case toggleReminder
    case snoozeReminder
    case cycleBlueLightLevel

    var title: String {
        switch self {
        case .toggleMainPanel:
            return "打开主界面"
        case .toggleReminder:
            return "暂停/继续提醒"
        case .snoozeReminder:
            return "稍后提醒"
        case .cycleBlueLightLevel:
            return "切换护眼模式"
        }
    }

    var defaultBinding: ShortcutBinding {
        switch self {
        case .toggleMainPanel:
            return ShortcutBinding(keyCode: 49, modifierFlagsRaw: 1_179_648) // Command + Shift + Space
        case .toggleReminder:
            return ShortcutBinding(keyCode: 35, modifierFlagsRaw: 1_179_648) // Command + Shift + P
        case .snoozeReminder:
            return ShortcutBinding(keyCode: 1, modifierFlagsRaw: 1_179_648) // Command + Shift + S
        case .cycleBlueLightLevel:
            return ShortcutBinding(keyCode: 37, modifierFlagsRaw: 1_179_648) // Command + Shift + L
        }
    }
}

struct AppSettings: Codable {
    var reminderEnabled: Bool
    var workIntervalMinutes: Int
    var breakDurationSeconds: Int
    var filterLevelKey: String
    var useBackgroundImage: Bool
    var playBreakFinishedSound: Bool
    var shortcutKeyCode: UInt16
    var shortcutModifierFlagsRaw: UInt
    var shortcutToggleMainPanelKeyCode: UInt16
    var shortcutToggleMainPanelModifierFlagsRaw: UInt
    var shortcutToggleReminderKeyCode: UInt16
    var shortcutToggleReminderModifierFlagsRaw: UInt
    var shortcutSnoozeReminderKeyCode: UInt16
    var shortcutSnoozeReminderModifierFlagsRaw: UInt
    var shortcutCycleBlueLightLevelKeyCode: UInt16
    var shortcutCycleBlueLightLevelModifierFlagsRaw: UInt
    var backgroundImageOpacity: Double
    var mainWindowOpacity: Double
    var reminderWindowOpacity: Double
    var settingsWindowOpacity: Double

    static let `default` = AppSettings(
        reminderEnabled: true,
        workIntervalMinutes: 20,
        breakDurationSeconds: 20,
        filterLevelKey: "off",
        useBackgroundImage: true,
        playBreakFinishedSound: false,
        shortcutKeyCode: ShortcutAction.toggleMainPanel.defaultBinding.keyCode,
        shortcutModifierFlagsRaw: ShortcutAction.toggleMainPanel.defaultBinding.modifierFlagsRaw,
        shortcutToggleMainPanelKeyCode: ShortcutAction.toggleMainPanel.defaultBinding.keyCode,
        shortcutToggleMainPanelModifierFlagsRaw: ShortcutAction.toggleMainPanel.defaultBinding.modifierFlagsRaw,
        shortcutToggleReminderKeyCode: ShortcutAction.toggleReminder.defaultBinding.keyCode,
        shortcutToggleReminderModifierFlagsRaw: ShortcutAction.toggleReminder.defaultBinding.modifierFlagsRaw,
        shortcutSnoozeReminderKeyCode: ShortcutAction.snoozeReminder.defaultBinding.keyCode,
        shortcutSnoozeReminderModifierFlagsRaw: ShortcutAction.snoozeReminder.defaultBinding.modifierFlagsRaw,
        shortcutCycleBlueLightLevelKeyCode: ShortcutAction.cycleBlueLightLevel.defaultBinding.keyCode,
        shortcutCycleBlueLightLevelModifierFlagsRaw: ShortcutAction.cycleBlueLightLevel.defaultBinding.modifierFlagsRaw,
        backgroundImageOpacity: 1.0,
        mainWindowOpacity: 0.80,
        reminderWindowOpacity: 0.78,
        settingsWindowOpacity: 0.78
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
        case shortcutToggleMainPanelKeyCode
        case shortcutToggleMainPanelModifierFlagsRaw
        case shortcutToggleReminderKeyCode
        case shortcutToggleReminderModifierFlagsRaw
        case shortcutSnoozeReminderKeyCode
        case shortcutSnoozeReminderModifierFlagsRaw
        case shortcutCycleBlueLightLevelKeyCode
        case shortcutCycleBlueLightLevelModifierFlagsRaw
        case backgroundImageOpacity
        case mainWindowOpacity
        case reminderWindowOpacity
        case settingsWindowOpacity
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
        shortcutToggleMainPanelKeyCode: UInt16,
        shortcutToggleMainPanelModifierFlagsRaw: UInt,
        shortcutToggleReminderKeyCode: UInt16,
        shortcutToggleReminderModifierFlagsRaw: UInt,
        shortcutSnoozeReminderKeyCode: UInt16,
        shortcutSnoozeReminderModifierFlagsRaw: UInt,
        shortcutCycleBlueLightLevelKeyCode: UInt16,
        shortcutCycleBlueLightLevelModifierFlagsRaw: UInt,
        backgroundImageOpacity: Double,
        mainWindowOpacity: Double,
        reminderWindowOpacity: Double,
        settingsWindowOpacity: Double
    ) {
        self.reminderEnabled = reminderEnabled
        self.workIntervalMinutes = workIntervalMinutes
        self.breakDurationSeconds = breakDurationSeconds
        self.filterLevelKey = filterLevelKey
        self.useBackgroundImage = useBackgroundImage
        self.playBreakFinishedSound = playBreakFinishedSound
        self.shortcutKeyCode = shortcutKeyCode
        self.shortcutModifierFlagsRaw = shortcutModifierFlagsRaw
        self.shortcutToggleMainPanelKeyCode = shortcutToggleMainPanelKeyCode
        self.shortcutToggleMainPanelModifierFlagsRaw = shortcutToggleMainPanelModifierFlagsRaw
        self.shortcutToggleReminderKeyCode = shortcutToggleReminderKeyCode
        self.shortcutToggleReminderModifierFlagsRaw = shortcutToggleReminderModifierFlagsRaw
        self.shortcutSnoozeReminderKeyCode = shortcutSnoozeReminderKeyCode
        self.shortcutSnoozeReminderModifierFlagsRaw = shortcutSnoozeReminderModifierFlagsRaw
        self.shortcutCycleBlueLightLevelKeyCode = shortcutCycleBlueLightLevelKeyCode
        self.shortcutCycleBlueLightLevelModifierFlagsRaw = shortcutCycleBlueLightLevelModifierFlagsRaw
        self.backgroundImageOpacity = backgroundImageOpacity
        self.mainWindowOpacity = mainWindowOpacity
        self.reminderWindowOpacity = reminderWindowOpacity
        self.settingsWindowOpacity = settingsWindowOpacity
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

        let legacyKeyCode = try container.decodeIfPresent(UInt16.self, forKey: .shortcutKeyCode) ?? defaults.shortcutKeyCode
        let legacyModifierFlagsRaw = try container.decodeIfPresent(UInt.self, forKey: .shortcutModifierFlagsRaw) ?? defaults.shortcutModifierFlagsRaw
        shortcutKeyCode = legacyKeyCode
        shortcutModifierFlagsRaw = legacyModifierFlagsRaw

        shortcutToggleMainPanelKeyCode = try container.decodeIfPresent(UInt16.self, forKey: .shortcutToggleMainPanelKeyCode) ?? legacyKeyCode
        shortcutToggleMainPanelModifierFlagsRaw = try container.decodeIfPresent(UInt.self, forKey: .shortcutToggleMainPanelModifierFlagsRaw) ?? legacyModifierFlagsRaw
        shortcutToggleReminderKeyCode = try container.decodeIfPresent(UInt16.self, forKey: .shortcutToggleReminderKeyCode) ?? defaults.shortcutToggleReminderKeyCode
        shortcutToggleReminderModifierFlagsRaw = try container.decodeIfPresent(UInt.self, forKey: .shortcutToggleReminderModifierFlagsRaw) ?? defaults.shortcutToggleReminderModifierFlagsRaw
        shortcutSnoozeReminderKeyCode = try container.decodeIfPresent(UInt16.self, forKey: .shortcutSnoozeReminderKeyCode) ?? defaults.shortcutSnoozeReminderKeyCode
        shortcutSnoozeReminderModifierFlagsRaw = try container.decodeIfPresent(UInt.self, forKey: .shortcutSnoozeReminderModifierFlagsRaw) ?? defaults.shortcutSnoozeReminderModifierFlagsRaw
        shortcutCycleBlueLightLevelKeyCode = try container.decodeIfPresent(UInt16.self, forKey: .shortcutCycleBlueLightLevelKeyCode) ?? defaults.shortcutCycleBlueLightLevelKeyCode
        shortcutCycleBlueLightLevelModifierFlagsRaw = try container.decodeIfPresent(UInt.self, forKey: .shortcutCycleBlueLightLevelModifierFlagsRaw) ?? defaults.shortcutCycleBlueLightLevelModifierFlagsRaw

        backgroundImageOpacity = try container.decodeIfPresent(Double.self, forKey: .backgroundImageOpacity) ?? defaults.backgroundImageOpacity
        mainWindowOpacity = try container.decodeIfPresent(Double.self, forKey: .mainWindowOpacity) ?? defaults.mainWindowOpacity
        reminderWindowOpacity = try container.decodeIfPresent(Double.self, forKey: .reminderWindowOpacity) ?? defaults.reminderWindowOpacity
        settingsWindowOpacity = try container.decodeIfPresent(Double.self, forKey: .settingsWindowOpacity) ?? defaults.settingsWindowOpacity
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
