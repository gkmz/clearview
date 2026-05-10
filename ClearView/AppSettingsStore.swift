import Foundation

struct ShortcutBinding: Codable, Equatable {
    var keyCode: UInt16
    var modifierFlagsRaw: UInt
}

enum RhythmMode: String, CaseIterable, Codable, Equatable {
    case eyeCare
    case pomodoro

    var title: String {
        switch self {
        case .eyeCare: return "护眼"
        case .pomodoro: return "番茄"
        }
    }

    var statusTitle: String {
        switch self {
        case .eyeCare: return "护眼节奏"
        case .pomodoro: return "番茄专注"
        }
    }

    static func fromSettingsKey(_ key: String) -> RhythmMode {
        RhythmMode(rawValue: key) ?? .eyeCare
    }

    var settingsKey: String { rawValue }
}

/// 提醒弹窗醒目程度：轻度更克制、重度更抢眼，默认中度兼顾多数用户。
enum ReminderIntensityLevel: String, CaseIterable, Codable, Equatable {
    case light
    case medium
    case strong

    var title: String {
        switch self {
        case .light:
            return "轻度（更克制）"
        case .medium:
            return "中度（默认）"
        case .strong:
            return "重度（更醒目）"
        }
    }

    var shortTitle: String {
        switch self {
        case .light: return "轻度"
        case .medium: return "中度"
        case .strong: return "重度"
        }
    }

    /// 面板宽度（与 `ReminderFloatingView` 外框一致）。
    var panelWidth: CGFloat {
        switch self {
        case .light: return 480
        case .medium: return 560
        case .strong: return 640
        }
    }

    var panelHeight: CGFloat {
        switch self {
        case .light: return 268
        case .medium: return 300
        case .strong: return 340
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .light: return 16
        case .medium: return 20
        case .strong: return 24
        }
    }

    var vStackSpacing: CGFloat {
        switch self {
        case .light: return 12
        case .medium: return 16
        case .strong: return 20
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .light: return 32
        case .medium: return 40
        case .strong: return 48
        }
    }

    var verticalPadding: CGFloat {
        switch self {
        case .light: return 24
        case .medium: return 30
        case .strong: return 34
        }
    }

    var countdownFontSize: CGFloat {
        switch self {
        case .light: return 70
        case .medium: return 84
        case .strong: return 96
        }
    }

    var countdownFrameHeight: CGFloat {
        switch self {
        case .light: return 76
        case .medium: return 90
        case .strong: return 102
        }
    }

    var titleFontSize: CGFloat {
        switch self {
        case .light: return 22
        case .medium: return 26
        case .strong: return 30
        }
    }

    var titleFrameHeight: CGFloat {
        switch self {
        case .light: return 30
        case .medium: return 34
        case .strong: return 38
        }
    }

    var messageFontSize: CGFloat {
        switch self {
        case .light: return 15
        case .medium: return 17
        case .strong: return 19
        }
    }

    var messageFrameHeight: CGFloat {
        switch self {
        case .light: return 20
        case .medium: return 22
        case .strong: return 24
        }
    }

    var actionIconPointSize: CGFloat {
        switch self {
        case .light: return 20
        case .medium: return 24
        case .strong: return 28
        }
    }

    var actionButtonSide: CGFloat {
        switch self {
        case .light: return 52
        case .medium: return 58
        case .strong: return 64
        }
    }

    var actionHStackSpacing: CGFloat {
        switch self {
        case .light: return 18
        case .medium: return 22
        case .strong: return 26
        }
    }

    var shadowRadius: CGFloat {
        switch self {
        case .light: return 22
        case .medium: return 30
        case .strong: return 38
        }
    }

    static func fromSettingsKey(_ key: String) -> ReminderIntensityLevel {
        switch key {
        case "light": return .light
        case "strong": return .strong
        default: return .medium
        }
    }

    var settingsKey: String { rawValue }
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
        // 默认快捷键尽量“可记忆 + 低冲突”；后续若有冲突由用户在设置中覆盖。
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
    var rhythmModeKey: String
    var workIntervalMinutes: Int
    var breakDurationSeconds: Int
    var eyeIntervalMinutes: Int
    var eyeBreakDurationSeconds: Int
    var pomodoroFocusMinutes: Int
    var pomodoroBreakMinutes: Int
    var pomodoroEyeBreakEnabled: Bool
    var mergeEyeBreakThresholdSeconds: Int
    var filterLevelKey: String
    var useBackgroundImage: Bool
    var playBreakFinishedSound: Bool
    // 兼容历史配置（单一主快捷键字段），迁移期保留，避免老用户升级后丢失快捷键。
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
    /// 提醒弹窗强度：`light` / `medium` / `strong`，缺省按中度解码。
    var reminderIntensityKey: String

    static let `default` = AppSettings(
        reminderEnabled: true,
        rhythmModeKey: RhythmMode.eyeCare.settingsKey,
        workIntervalMinutes: 20,
        breakDurationSeconds: 20,
        eyeIntervalMinutes: 20,
        eyeBreakDurationSeconds: 20,
        pomodoroFocusMinutes: 25,
        pomodoroBreakMinutes: 5,
        pomodoroEyeBreakEnabled: true,
        mergeEyeBreakThresholdSeconds: 120,
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
        settingsWindowOpacity: 0.78,
        reminderIntensityKey: ReminderIntensityLevel.medium.settingsKey
    )

    enum CodingKeys: String, CodingKey {
        case reminderEnabled
        case rhythmModeKey
        case workIntervalMinutes
        case breakDurationSeconds
        case eyeIntervalMinutes
        case eyeBreakDurationSeconds
        case pomodoroFocusMinutes
        case pomodoroBreakMinutes
        case pomodoroEyeBreakEnabled
        case mergeEyeBreakThresholdSeconds
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
        case reminderIntensityKey
    }

    init(
        reminderEnabled: Bool,
        rhythmModeKey: String,
        workIntervalMinutes: Int,
        breakDurationSeconds: Int,
        eyeIntervalMinutes: Int,
        eyeBreakDurationSeconds: Int,
        pomodoroFocusMinutes: Int,
        pomodoroBreakMinutes: Int,
        pomodoroEyeBreakEnabled: Bool,
        mergeEyeBreakThresholdSeconds: Int,
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
        settingsWindowOpacity: Double,
        reminderIntensityKey: String
    ) {
        self.reminderEnabled = reminderEnabled
        self.rhythmModeKey = rhythmModeKey
        self.workIntervalMinutes = workIntervalMinutes
        self.breakDurationSeconds = breakDurationSeconds
        self.eyeIntervalMinutes = eyeIntervalMinutes
        self.eyeBreakDurationSeconds = eyeBreakDurationSeconds
        self.pomodoroFocusMinutes = pomodoroFocusMinutes
        self.pomodoroBreakMinutes = pomodoroBreakMinutes
        self.pomodoroEyeBreakEnabled = pomodoroEyeBreakEnabled
        self.mergeEyeBreakThresholdSeconds = mergeEyeBreakThresholdSeconds
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
        self.reminderIntensityKey = reminderIntensityKey
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = AppSettings.default
        reminderEnabled = try container.decodeIfPresent(Bool.self, forKey: .reminderEnabled) ?? defaults.reminderEnabled
        rhythmModeKey = try container.decodeIfPresent(String.self, forKey: .rhythmModeKey) ?? defaults.rhythmModeKey
        let legacyWorkIntervalMinutes = try container.decodeIfPresent(Int.self, forKey: .workIntervalMinutes) ?? defaults.workIntervalMinutes
        let legacyBreakDurationSeconds = try container.decodeIfPresent(Int.self, forKey: .breakDurationSeconds) ?? defaults.breakDurationSeconds
        workIntervalMinutes = legacyWorkIntervalMinutes
        breakDurationSeconds = legacyBreakDurationSeconds
        eyeIntervalMinutes = try container.decodeIfPresent(Int.self, forKey: .eyeIntervalMinutes) ?? legacyWorkIntervalMinutes
        eyeBreakDurationSeconds = try container.decodeIfPresent(Int.self, forKey: .eyeBreakDurationSeconds) ?? legacyBreakDurationSeconds
        pomodoroFocusMinutes = try container.decodeIfPresent(Int.self, forKey: .pomodoroFocusMinutes) ?? defaults.pomodoroFocusMinutes
        pomodoroBreakMinutes = try container.decodeIfPresent(Int.self, forKey: .pomodoroBreakMinutes) ?? defaults.pomodoroBreakMinutes
        pomodoroEyeBreakEnabled = try container.decodeIfPresent(Bool.self, forKey: .pomodoroEyeBreakEnabled) ?? defaults.pomodoroEyeBreakEnabled
        mergeEyeBreakThresholdSeconds = try container.decodeIfPresent(Int.self, forKey: .mergeEyeBreakThresholdSeconds) ?? defaults.mergeEyeBreakThresholdSeconds
        filterLevelKey = try container.decodeIfPresent(String.self, forKey: .filterLevelKey) ?? defaults.filterLevelKey
        useBackgroundImage = try container.decodeIfPresent(Bool.self, forKey: .useBackgroundImage) ?? defaults.useBackgroundImage
        playBreakFinishedSound = try container.decodeIfPresent(Bool.self, forKey: .playBreakFinishedSound) ?? defaults.playBreakFinishedSound

        // 关键流程：先读取旧字段，再作为新字段的回退值，保证历史版本平滑升级到多快捷键结构。
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
        reminderIntensityKey = try container.decodeIfPresent(String.self, forKey: .reminderIntensityKey) ?? defaults.reminderIntensityKey
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
            // 配置损坏时回退默认值，避免影响应用启动。
            return .default
        }
    }

    func save(_ settings: AppSettings) {
        do {
            let data = try JSONEncoder().encode(settings)
            defaults.set(data, forKey: key)
        } catch {
            // 写入失败时不打断主流程，保持当前内存状态可继续使用。
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
