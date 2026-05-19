//
//  ClearViewApp.swift
//  ClearView
//
//  Created by mo on 30.4.2026.
//

import AppKit
import SwiftUI
import Foundation
import Combine
import ServiceManagement

@main
struct ClearViewApp: App {
    @StateObject private var appState = AppState()

    private var menuBarTemplateIcon: NSImage? {
        guard let url = Bundle.main.url(forResource: "icon", withExtension: "png"),
              let image = NSImage(contentsOf: url) else {
            return nil
        }
        // 关键流程：菜单栏使用专用透明模板图标，不直接使用彩色 App Logo，避免深色背景导致图标不可见。
        image.isTemplate = true
        // 关键流程：NSStatusItem 会参考 NSImage 的 point size；先压到菜单栏合适尺寸，避免大 PNG 被原始尺寸撑开。
        image.size = NSSize(width: 18, height: 18)
        return image
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
        } label: {
            if let image = menuBarTemplateIcon {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
            } else {
                Label("ClearView", systemImage: "eye")
            }
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    enum ReminderPhase {
        case none
        case preparing
        case resting
        case pomodoroResting
        case completed
    }

    @Published var reminderEnabled = true
    @Published var rhythmMode: RhythmMode = .eyeCare
    @Published var workIntervalMinutes: Int = 20
    @Published var breakDurationSeconds: Int = 20
    @Published var pomodoroFocusMinutes: Int = 25
    @Published var pomodoroBreakMinutes: Int = 5
    @Published var secondsUntilBreak: Int = 20 * 60
    @Published var filterLevel: BlueLightLevel = .off
    @Published var useBackgroundImage = true
    @Published var playBreakFinishedSound = false
    @Published var shortcutKeyCode: UInt16 = 49
    @Published var shortcutModifierFlagsRaw: UInt = 1_179_648
    @Published var reminderToggleShortcutKeyCode: UInt16 = 35
    @Published var reminderToggleShortcutModifierFlagsRaw: UInt = 1_179_648
    @Published var snoozeReminderShortcutKeyCode: UInt16 = 1
    @Published var snoozeReminderShortcutModifierFlagsRaw: UInt = 1_179_648
    @Published var toggleRhythmShortcutKeyCode: UInt16 = 15
    @Published var toggleRhythmShortcutModifierFlagsRaw: UInt = 1_179_648
    @Published var cycleFilterShortcutKeyCode: UInt16 = 37
    @Published var cycleFilterShortcutModifierFlagsRaw: UInt = 1_179_648
    @Published var backgroundImageOpacity: Double = 1.0
    @Published var mainWindowOpacity: Double = 0.80
    @Published var reminderWindowOpacity: Double = 0.78
    @Published var settingsWindowOpacity: Double = 0.78
    /// 提醒弹窗强度（轻/中/重），控制面板尺寸与字号醒目度。
    @Published var reminderIntensity: ReminderIntensityLevel = .medium
    @Published var launchAtLoginEnabled = false
    @Published var startTimerOnLaunch = true
    @Published var statusText: String = "陪你护眼"
    @Published var reminderPhase: ReminderPhase = .none
    @Published var breakSecondsLeft: Int = 20
    @Published var activeBreakKind: RhythmBreakKind = .eye
    @Published var isReminderPreview = false

    var canCompleteCurrentBreak: Bool {
        if isReminderPreview || reminderPhase == .completed {
            return true
        }
        guard reminderPhase == .resting || reminderPhase == .pomodoroResting else {
            return false
        }

        let totalBreakSeconds = activeBreakKind == .pomodoro
            ? max(1, pomodoroBreakMinutes) * 60
            : max(5, breakDurationSeconds)
        let minimumEyeRelaxSeconds = min(20, totalBreakSeconds)
        let elapsedSeconds = max(0, totalBreakSeconds - breakSecondsLeft)
        return elapsedSeconds >= minimumEyeRelaxSeconds
    }

    private let reminderService = ReminderService()
    private let blueLightService: BlueLightFiltering
    private let shortcutManager = GlobalShortcutManager.shared
    private let settingsStore = AppSettingsStore()
    private let preparationSeconds = 5
    private let previewSeconds = 20
    private var pomodoroEyeBreakEnabled = true
    private var mergeEyeBreakThresholdSeconds: Int = 120
    private var breakCountdownTimer: Timer?
    private var displayNotificationObservers = [NSObjectProtocol]()
    private var mainPanel: MainPanelController?
    private var reminderPanel: ReminderPanelController?
    private var settingsPanel: SettingsPanelController?
    private var aboutPanel: AboutPanelController?

    convenience init() {
        self.init(blueLightService: BlueLightFilterService())
    }

    init(blueLightService: BlueLightFiltering) {
        self.blueLightService = blueLightService
        loadSettings()
        registerForDisplayNotifications()

        reminderService.onTick = { [weak self] tick in
            guard let self else { return }
            Task { @MainActor in
                self.secondsUntilBreak = tick.focusSecondsRemaining
            }
        }

        reminderService.onBreakTriggered = { [weak self] kind in
            guard let self else { return }
            Task { @MainActor in
                guard self.reminderEnabled, self.reminderPhase == .none else { return }
                self.startReminderFlow(kind: kind)
            }
        }

        if reminderEnabled, startTimerOnLaunch {
            reminderService.start(configuration: rhythmConfiguration)
        } else {
            reminderEnabled = false
            reminderService.stop()
        }
        // 应用启动时集中注册所有全局快捷键，若任一失败立即反馈给用户。
        let mainPanelShortcutRegistered = shortcutManager.configure(
            action: .toggleMainPanel,
            keyCode: shortcutKeyCode,
            modifierFlagsRaw: shortcutModifierFlagsRaw
        ) { [weak self] in
            Task { @MainActor in
                self?.toggleMainPanel()
            }
        }
        let reminderToggleShortcutRegistered = shortcutManager.configure(
            action: .toggleReminder,
            keyCode: reminderToggleShortcutKeyCode,
            modifierFlagsRaw: reminderToggleShortcutModifierFlagsRaw
        ) { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.toggleReminderFromShortcut()
            }
        }
        let cycleFilterShortcutRegistered = shortcutManager.configure(
            action: .cycleBlueLightLevel,
            keyCode: cycleFilterShortcutKeyCode,
            modifierFlagsRaw: cycleFilterShortcutModifierFlagsRaw
        ) { [weak self] in
            Task { @MainActor in
                self?.cycleBlueLightLevel()
            }
        }
        let snoozeReminderShortcutRegistered = shortcutManager.configure(
            action: .snoozeReminder,
            keyCode: snoozeReminderShortcutKeyCode,
            modifierFlagsRaw: snoozeReminderShortcutModifierFlagsRaw
        ) { [weak self] in
            Task { @MainActor in
                self?.snoozeReminderFromShortcut()
            }
        }
        let rhythmShortcutRegistered = shortcutManager.configure(
            action: .toggleRhythmMode,
            keyCode: toggleRhythmShortcutKeyCode,
            modifierFlagsRaw: toggleRhythmShortcutModifierFlagsRaw
        ) { [weak self] in
            Task { @MainActor in
                self?.toggleRhythmMode()
            }
        }
        if !mainPanelShortcutRegistered {
            statusText = "主界面快捷键注册失败，请在设置中重新选择"
        } else if !reminderToggleShortcutRegistered {
            statusText = "暂停提醒快捷键注册失败，请在设置中重新选择"
        } else if !cycleFilterShortcutRegistered {
            statusText = "护眼模式快捷键注册失败，请在设置中重新选择"
        } else if !snoozeReminderShortcutRegistered {
            statusText = "稍后提醒快捷键注册失败，请在设置中重新选择"
        } else if !rhythmShortcutRegistered {
            statusText = "节奏快捷键注册失败，请在设置中重新选择"
        }
        mainPanel = MainPanelController(appState: self)
        reminderPanel = ReminderPanelController(appState: self)
        settingsPanel = SettingsPanelController(appState: self)
        aboutPanel = AboutPanelController(appState: self)
    }

    func showMainPanel() {
        mainPanel?.show()
    }

    func toggleMainPanel() {
        if mainPanel?.isVisible == true {
            settingsPanel?.hide()
            aboutPanel?.hide()
        }
        mainPanel?.toggle()
    }

    func hideMainPanel() {
        settingsPanel?.hide()
        aboutPanel?.hide()
        mainPanel?.hide()
    }

    func toggleSettingsPanel() {
        settingsPanel?.toggle(anchoredTo: mainPanel?.frame)
    }

    func hideSettingsPanel() {
        settingsPanel?.hide()
    }

    func showAboutPanel() {
        aboutPanel?.show(anchoredTo: mainPanel?.frame)
    }

    func hideAboutPanel() {
        aboutPanel?.hide()
    }

    func setMainPanelMovableByBackground(_ isMovable: Bool) {
        mainPanel?.setMovableByBackground(isMovable)
    }

    func toggleReminder(_ enabled: Bool) {
        reminderEnabled = enabled
        if enabled {
            reminderService.resume(configuration: rhythmConfiguration)
            statusText = "继续当前计时"
        } else {
            reminderService.stop()
            statusText = "先不打扰"
        }
        persistSettings()
    }

    func toggleReminderFromShortcut() {
        // 舒眼完成后，快捷键应等价于点击“继续”，关闭提醒窗并重新开始计时。
        if reminderPhase == .completed {
            completeBreak()
            return
        }

        // 非提醒弹窗阶段保持原有语义，作为“全局提醒开关”切换。
        toggleReminder(!reminderEnabled)
    }

    func snoozeReminderFromShortcut() {
        // 稍后提醒只处理当前正在展示的提醒窗，避免在平时误改计时节奏。
        guard reminderPhase == .preparing || reminderPhase == .resting else { return }
        snoozeBreak(minutes: 5)
    }

    func updateInterval(_ minutes: Int) {
        workIntervalMinutes = max(1, minutes)
        if reminderEnabled {
            reminderService.start(configuration: rhythmConfiguration)
            statusText = "节奏已调整"
        }
        persistSettings()
    }

    func updateBreakDuration(_ seconds: Int) {
        breakDurationSeconds = max(5, seconds)
        breakSecondsLeft = breakDurationSeconds
        statusText = "休息时间已调整"
        persistSettings()
    }

    func updateRhythmMode(_ mode: RhythmMode) {
        guard rhythmMode != mode else { return }
        rhythmMode = mode
        statusText = mode == .eyeCare ? "已切换到护眼，重新开始倒计时" : "已切换到番茄，开始新一轮专注"
        if reminderEnabled {
            reminderService.start(configuration: rhythmConfiguration)
        } else {
            reminderService.reset(configuration: rhythmConfiguration)
        }
        secondsUntilBreak = rhythmConfiguration.initialFocusSeconds
        persistSettings()
    }

    func toggleRhythmMode() {
        updateRhythmMode(rhythmMode == .eyeCare ? .pomodoro : .eyeCare)
    }

    func updatePomodoroFocus(_ minutes: Int) {
        pomodoroFocusMinutes = max(1, minutes)
        statusText = "专注时间已调整"
        if reminderEnabled, rhythmMode == .pomodoro {
            reminderService.start(configuration: rhythmConfiguration)
        }
        persistSettings()
    }

    func updatePomodoroBreak(_ minutes: Int) {
        pomodoroBreakMinutes = max(1, minutes)
        statusText = "番茄休息已调整"
        persistSettings()
    }

    func resetReminderTimer() {
        reminderEnabled = false
        reminderService.reset(configuration: rhythmConfiguration)
        statusText = "重新开始"
        persistSettings()
    }

    func applyFilter(_ level: BlueLightLevel) {
        filterLevel = level
        // 蓝光档位切换时立即应用到所有可用显示器。
        blueLightService.apply(level: level)
        statusText = "护眼：\(level.title)"
        persistSettings()
    }

    func updateBackgroundImageEnabled(_ enabled: Bool) {
        useBackgroundImage = enabled
        // 无背景图时保留最低底色，避免主界面完全透明后文字失去承托。
        if !enabled {
            mainWindowOpacity = normalizedMainWindowOpacity(mainWindowOpacity, useBackgroundImage: false)
        }
        statusText = enabled ? "背景图片已启用" : "背景图片已关闭"
        persistSettings()
    }

    func updateBreakFinishedSoundEnabled(_ enabled: Bool) {
        playBreakFinishedSound = enabled
        statusText = enabled ? "结束提示音已启用" : "结束提示音已关闭"
        persistSettings()
    }

    func updateLaunchAtLoginEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLoginEnabled = enabled
            statusText = enabled ? "已开启开机启动" : "已关闭开机启动"
            persistSettings()
        } catch {
            launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
            statusText = "开机启动设置失败"
        }
    }

    func updateStartTimerOnLaunch(_ enabled: Bool) {
        startTimerOnLaunch = enabled
        statusText = enabled ? "启动后自动计时" : "启动后保持暂停"
        persistSettings()
    }

    func updateShortcut(action: ShortcutAction, keyCode: UInt16, modifierFlagsRaw: UInt) {
        // 普通按键至少需要一个修饰键；F1-F20 这类功能键允许单独作为全局快捷键。
        let flags = NSEvent.ModifierFlags(rawValue: modifierFlagsRaw)
            .intersection([.command, .shift, .option, .control])
        guard !flags.isEmpty || GlobalShortcutManager.isFunctionKey(keyCode) else {
            statusText = "普通按键需配合修饰键"
            return
        }

        let normalizedBinding = ShortcutBinding(keyCode: keyCode, modifierFlagsRaw: flags.rawValue)
        let oldBinding = binding(for: action)

        if hasInternalConflict(for: action, binding: normalizedBinding) {
            statusText = "该快捷键已被应用内其他功能使用"
            return
        }

        setBinding(normalizedBinding, for: action)
        let success = shortcutManager.updateShortcut(action: action, keyCode: keyCode, modifierFlagsRaw: flags.rawValue)
        if success {
            statusText = "快捷键已更新"
        } else {
            setBinding(oldBinding, for: action)
            _ = shortcutManager.updateShortcut(
                action: action,
                keyCode: oldBinding.keyCode,
                modifierFlagsRaw: oldBinding.modifierFlagsRaw
            )
            statusText = "快捷键被系统占用，请换一组组合键"
        }
        persistSettings()
    }

    func shortcutDisplayString(for action: ShortcutAction) -> String {
        let binding = binding(for: action)
        return shortcutManager.shortcutDisplayString(
            keyCode: binding.keyCode,
            modifierFlagsRaw: binding.modifierFlagsRaw
        )
    }

    private func binding(for action: ShortcutAction) -> ShortcutBinding {
        switch action {
        case .toggleMainPanel:
            return ShortcutBinding(keyCode: shortcutKeyCode, modifierFlagsRaw: shortcutModifierFlagsRaw)
        case .toggleReminder:
            return ShortcutBinding(keyCode: reminderToggleShortcutKeyCode, modifierFlagsRaw: reminderToggleShortcutModifierFlagsRaw)
        case .snoozeReminder:
            return ShortcutBinding(keyCode: snoozeReminderShortcutKeyCode, modifierFlagsRaw: snoozeReminderShortcutModifierFlagsRaw)
        case .toggleRhythmMode:
            return ShortcutBinding(keyCode: toggleRhythmShortcutKeyCode, modifierFlagsRaw: toggleRhythmShortcutModifierFlagsRaw)
        case .cycleBlueLightLevel:
            return ShortcutBinding(keyCode: cycleFilterShortcutKeyCode, modifierFlagsRaw: cycleFilterShortcutModifierFlagsRaw)
        }
    }

    private func setBinding(_ binding: ShortcutBinding, for action: ShortcutAction) {
        switch action {
        case .toggleMainPanel:
            shortcutKeyCode = binding.keyCode
            shortcutModifierFlagsRaw = binding.modifierFlagsRaw
        case .toggleReminder:
            reminderToggleShortcutKeyCode = binding.keyCode
            reminderToggleShortcutModifierFlagsRaw = binding.modifierFlagsRaw
        case .snoozeReminder:
            snoozeReminderShortcutKeyCode = binding.keyCode
            snoozeReminderShortcutModifierFlagsRaw = binding.modifierFlagsRaw
        case .toggleRhythmMode:
            toggleRhythmShortcutKeyCode = binding.keyCode
            toggleRhythmShortcutModifierFlagsRaw = binding.modifierFlagsRaw
        case .cycleBlueLightLevel:
            cycleFilterShortcutKeyCode = binding.keyCode
            cycleFilterShortcutModifierFlagsRaw = binding.modifierFlagsRaw
        }
    }

    private func hasInternalConflict(for action: ShortcutAction, binding candidateBinding: ShortcutBinding) -> Bool {
        ShortcutAction.allCases.contains { candidate in
            guard candidate != action else { return false }
            return binding(for: candidate) == candidateBinding
        }
    }

    var shortcutDisplayString: String {
        shortcutDisplayString(for: .toggleMainPanel)
    }

    func updateMainWindowOpacity(_ value: Double) {
        // 有背景图时允许底色完全透明；无背景图时保留最低底色保证可读性。
        mainWindowOpacity = normalizedMainWindowOpacity(value, useBackgroundImage: useBackgroundImage)
        statusText = "主界面透明度已调整"
        persistSettings()
    }

    func updateBackgroundImageOpacity(_ value: Double) {
        backgroundImageOpacity = min(max(value, 0.25), 1.0)
        statusText = "背景图透明度已调整"
        persistSettings()
    }

    func updateReminderWindowOpacity(_ value: Double) {
        // 提示窗透明度单独可调，兼顾提醒可见性与通透感。
        reminderWindowOpacity = min(max(value, 0.25), 1.0)
        statusText = "提示窗透明度已调整"
        persistSettings()
    }

    func updateReminderIntensity(_ level: ReminderIntensityLevel) {
        let oldLevel = reminderIntensity
        reminderIntensity = level
        statusText = "提醒方式：\(level.shortTitle)"
        persistSettings()
        // 提醒方式切换可能在横幅与大浮窗之间变化，需按新方式重新定位，避免从右上角放大后超出屏幕。
        reminderPanel?.syncReminderPanelGeometryIfVisible(reposition: oldLevel != level)
    }

    func updateSettingsWindowOpacity(_ value: Double) {
        // 设置窗和关于窗共用同一透明度，保持辅助面板视觉一致。
        settingsWindowOpacity = min(max(value, 0.25), 1.0)
        statusText = "设置/关于窗透明度已调整"
        persistSettings()
    }

    func cycleBlueLightLevel() {
        let levels = BlueLightLevel.allCases
        guard let currentIndex = levels.firstIndex(of: filterLevel) else {
            applyFilter(levels.first ?? .off)
            return
        }
        let nextIndex = (currentIndex + 1) % levels.count
        applyFilter(levels[nextIndex])
    }

    func triggerTestReminderNow() {
        startReminderPreview()
    }

    func triggerTestReminder(after seconds: Int) {
        let safeSeconds = max(1, seconds)
        statusText = "\(safeSeconds)秒后预览提醒"
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(safeSeconds)) { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                guard self.reminderPhase == .none else { return }
                self.startReminderPreview()
            }
        }
    }

    func completeBreak() {
        if isReminderPreview {
            closeReminderPreview()
            return
        }

        reminderEnabled = true
        let completedBreakKind = activeBreakKind
        endReminderFlow()
        statusText = completedBreakKind == .pomodoro ? AppCopy.Status.pomodoroFinished : AppCopy.Status.finished
        reminderService.completeBreak()
        persistSettings()
    }

    func skipBreak() {
        // 关键流程：用户点击“稍后/跳过”后会继续进入工作倒计时，按钮状态也必须回到“运行中”。
        reminderEnabled = true
        endReminderFlow()
        statusText = "先继续也可以"
        reminderService.skipBreak()
        persistSettings()
    }

    func snoozeBreak(minutes: Int = 5) {
        guard !isReminderPreview else {
            closeReminderPreview()
            return
        }
        // 关键流程：延迟提醒会恢复主倒计时，需同步开启 reminderEnabled，避免主界面仍显示“开始”按钮。
        reminderEnabled = true
        endReminderFlow()
        statusText = "\(minutes)分钟后再提醒"
        reminderService.snooze(minutes: minutes)
        persistSettings()
    }

    func quitApplication() {
        // 退出前恢复显示色彩，避免蓝光过滤状态残留。
        blueLightService.apply(level: .off)
        NSApplication.shared.terminate(nil)
    }

    private func startReminderPreview() {
        guard reminderPhase == .none else { return }
        isReminderPreview = true
        activeBreakKind = .eye
        reminderPhase = .resting
        breakSecondsLeft = previewSeconds
        statusText = "预览提醒"
        if reminderIntensity != .light {
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
        reminderPanel?.show()
        startPreviewCountdown()
    }

    private func closeReminderPreview() {
        reminderPhase = .none
        isReminderPreview = false
        breakSecondsLeft = breakDurationSeconds
        activeBreakKind = .eye
        breakCountdownTimer?.invalidate()
        breakCountdownTimer = nil
        reminderPanel?.hide()
        statusText = "预览已关闭"
    }

    private var rhythmConfiguration: RhythmConfiguration {
        RhythmConfiguration(
            mode: rhythmMode,
            eyeIntervalMinutes: workIntervalMinutes,
            eyeBreakDurationSeconds: breakDurationSeconds,
            pomodoroFocusMinutes: pomodoroFocusMinutes,
            pomodoroBreakMinutes: pomodoroBreakMinutes,
            pomodoroEyeBreakEnabled: pomodoroEyeBreakEnabled,
            mergeEyeBreakThresholdSeconds: mergeEyeBreakThresholdSeconds
        )
    }

    private func startReminderFlow(kind: RhythmBreakKind) {
        guard reminderPhase == .none else { return }
        reminderService.stop()
        activeBreakKind = kind
        // 先给用户 5 秒反应时间，再进入正式休息倒计时。
        reminderPhase = .preparing
        breakSecondsLeft = preparationSeconds
        statusText = kind == .pomodoro ? AppCopy.Status.pomodoroPreparing : AppCopy.Status.preparing
        NSApplication.shared.activate(ignoringOtherApps: true)
        reminderPanel?.show()
        startPreparationCountdown()
    }

    private func startPreparationCountdown() {
        breakCountdownTimer?.invalidate()
        breakCountdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                guard self.reminderPhase == .preparing else { return }
                self.breakSecondsLeft -= 1
                if self.breakSecondsLeft <= 0 {
                    self.reminderPhase = self.activeBreakKind == .pomodoro ? .pomodoroResting : .resting
                    self.breakSecondsLeft = self.activeBreakKind == .pomodoro ? self.pomodoroBreakMinutes * 60 : self.breakDurationSeconds
                    self.statusText = self.activeBreakKind == .pomodoro
                        ? AppCopy.Status.pomodoroResting
                        : AppCopy.Status.resting
                    self.reminderPanel?.refresh()
                    self.breakCountdownTimer?.invalidate()
                    self.breakCountdownTimer = nil
                    self.startBreakCountdown()
                } else {
                    // 透明提示窗中的大号倒计时每秒变化时，重建内容视图以彻底清空上一帧数字残影。
                    self.reminderPanel?.refresh()
                }
            }
        }
        if let timer = breakCountdownTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func startBreakCountdown() {
        breakCountdownTimer?.invalidate()
        breakCountdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                guard self.reminderPhase == .resting || self.reminderPhase == .pomodoroResting else { return }
                self.breakSecondsLeft -= 1
                if self.breakSecondsLeft <= 0 {
                    // 休息倒计时结束后不自动关闭浮窗，等待用户点击继续按钮。
                    self.reminderPhase = .completed
                    self.breakSecondsLeft = 0
                    self.statusText = self.activeBreakKind == .pomodoro
                        ? AppCopy.Status.pomodoroCompleted
                        : AppCopy.Status.completed
                    self.reminderPanel?.refresh()
                    if self.playBreakFinishedSound {
                        // 用户可能正在看远方，结束时可选用短促声音温柔提醒可以回来了。
                        self.playBreakFinishedSoundEffect()
                    }
                    self.breakCountdownTimer?.invalidate()
                    self.breakCountdownTimer = nil
                } else {
                    // 透明提示窗中的大号倒计时每秒变化时，重建内容视图以彻底清空上一帧数字残影。
                    self.reminderPanel?.refresh()
                }
            }
        }
        if let timer = breakCountdownTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func startPreviewCountdown() {
        breakCountdownTimer?.invalidate()
        breakCountdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                guard self.isReminderPreview else { return }
                self.breakSecondsLeft -= 1
                if self.breakSecondsLeft <= 0 {
                    self.reminderPhase = .completed
                    self.breakSecondsLeft = 0
                    self.statusText = "预览结束"
                    self.reminderPanel?.refresh()
                    self.breakCountdownTimer?.invalidate()
                    self.breakCountdownTimer = nil
                } else {
                    self.reminderPanel?.refresh()
                }
            }
        }
        if let timer = breakCountdownTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func endReminderFlow() {
        reminderPhase = .none
        breakSecondsLeft = breakDurationSeconds
        activeBreakKind = .eye
        isReminderPreview = false
        breakCountdownTimer?.invalidate()
        breakCountdownTimer = nil
        reminderPanel?.hide()
    }

    private func playBreakFinishedSoundEffect() {
        NSSound(named: "Glass")?.play()
    }

    private func loadSettings() {
        let settings = settingsStore.load()
        reminderEnabled = settings.reminderEnabled
        rhythmMode = RhythmMode.fromSettingsKey(settings.rhythmModeKey)
        workIntervalMinutes = max(1, settings.eyeIntervalMinutes)
        breakDurationSeconds = max(5, settings.eyeBreakDurationSeconds)
        pomodoroFocusMinutes = max(1, settings.pomodoroFocusMinutes)
        pomodoroBreakMinutes = max(1, settings.pomodoroBreakMinutes)
        pomodoroEyeBreakEnabled = settings.pomodoroEyeBreakEnabled
        mergeEyeBreakThresholdSeconds = max(0, settings.mergeEyeBreakThresholdSeconds)
        filterLevel = BlueLightLevel.fromSettingsKey(settings.filterLevelKey)
        useBackgroundImage = settings.useBackgroundImage
        playBreakFinishedSound = settings.playBreakFinishedSound
        // 新字段优先，旧字段只作为解码阶段的回退；这里统一使用新字段赋值到运行时状态。
        shortcutKeyCode = settings.shortcutToggleMainPanelKeyCode
        shortcutModifierFlagsRaw = settings.shortcutToggleMainPanelModifierFlagsRaw
        reminderToggleShortcutKeyCode = settings.shortcutToggleReminderKeyCode
        reminderToggleShortcutModifierFlagsRaw = settings.shortcutToggleReminderModifierFlagsRaw
        snoozeReminderShortcutKeyCode = settings.shortcutSnoozeReminderKeyCode
        snoozeReminderShortcutModifierFlagsRaw = settings.shortcutSnoozeReminderModifierFlagsRaw
        toggleRhythmShortcutKeyCode = settings.shortcutToggleRhythmModeKeyCode
        toggleRhythmShortcutModifierFlagsRaw = settings.shortcutToggleRhythmModeModifierFlagsRaw
        cycleFilterShortcutKeyCode = settings.shortcutCycleBlueLightLevelKeyCode
        cycleFilterShortcutModifierFlagsRaw = settings.shortcutCycleBlueLightLevelModifierFlagsRaw
        backgroundImageOpacity = min(max(settings.backgroundImageOpacity, 0.25), 1.0)
        mainWindowOpacity = normalizedMainWindowOpacity(settings.mainWindowOpacity, useBackgroundImage: useBackgroundImage)
        reminderWindowOpacity = min(max(settings.reminderWindowOpacity, 0.25), 1.0)
        settingsWindowOpacity = min(max(settings.settingsWindowOpacity, 0.25), 1.0)
        reminderIntensity = ReminderIntensityLevel.fromSettingsKey(settings.reminderIntensityKey)
        launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
        startTimerOnLaunch = settings.startTimerOnLaunch

        // 应用启动时恢复倒计时基础值，避免界面显示与配置不一致。
        secondsUntilBreak = workIntervalMinutes * 60
        breakSecondsLeft = breakDurationSeconds

        // 启动时恢复上次蓝光档位，让视觉状态连续。
        blueLightService.apply(level: filterLevel)
    }

    private func registerForDisplayNotifications() {
        let defaultCenter = NotificationCenter.default
        displayNotificationObservers.append(
            defaultCenter.addObserver(
                forName: NSApplication.didChangeScreenParametersNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    self.reapplyCurrentBlueLightFilter()
                }
            }
        )

        displayNotificationObservers.append(
            NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.screensDidWakeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    self.reapplyCurrentBlueLightFilter()
                }
            }
        )
    }

    private func reapplyCurrentBlueLightFilter() {
        blueLightService.apply(level: filterLevel)
    }

    private func normalizedMainWindowOpacity(_ value: Double, useBackgroundImage: Bool) -> Double {
        let minimumOpacity = useBackgroundImage ? 0.0 : 0.20
        return min(max(value, minimumOpacity), 1.0)
    }

    private func persistSettings() {
        let settings = AppSettings(
            reminderEnabled: reminderEnabled,
            rhythmModeKey: rhythmMode.settingsKey,
            workIntervalMinutes: workIntervalMinutes,
            breakDurationSeconds: breakDurationSeconds,
            eyeIntervalMinutes: workIntervalMinutes,
            eyeBreakDurationSeconds: breakDurationSeconds,
            pomodoroFocusMinutes: pomodoroFocusMinutes,
            pomodoroBreakMinutes: pomodoroBreakMinutes,
            pomodoroEyeBreakEnabled: pomodoroEyeBreakEnabled,
            mergeEyeBreakThresholdSeconds: mergeEyeBreakThresholdSeconds,
            filterLevelKey: filterLevel.settingsKey,
            useBackgroundImage: useBackgroundImage,
            playBreakFinishedSound: playBreakFinishedSound,
            shortcutKeyCode: shortcutKeyCode,
            shortcutModifierFlagsRaw: shortcutModifierFlagsRaw,
            // 写回时同步保留旧字段，确保未来回滚到旧版本时仍能读取到主快捷键。
            shortcutToggleMainPanelKeyCode: shortcutKeyCode,
            shortcutToggleMainPanelModifierFlagsRaw: shortcutModifierFlagsRaw,
            shortcutToggleReminderKeyCode: reminderToggleShortcutKeyCode,
            shortcutToggleReminderModifierFlagsRaw: reminderToggleShortcutModifierFlagsRaw,
            shortcutSnoozeReminderKeyCode: snoozeReminderShortcutKeyCode,
            shortcutSnoozeReminderModifierFlagsRaw: snoozeReminderShortcutModifierFlagsRaw,
            shortcutToggleRhythmModeKeyCode: toggleRhythmShortcutKeyCode,
            shortcutToggleRhythmModeModifierFlagsRaw: toggleRhythmShortcutModifierFlagsRaw,
            shortcutCycleBlueLightLevelKeyCode: cycleFilterShortcutKeyCode,
            shortcutCycleBlueLightLevelModifierFlagsRaw: cycleFilterShortcutModifierFlagsRaw,
            backgroundImageOpacity: backgroundImageOpacity,
            mainWindowOpacity: mainWindowOpacity,
            reminderWindowOpacity: reminderWindowOpacity,
            settingsWindowOpacity: settingsWindowOpacity,
            reminderIntensityKey: reminderIntensity.settingsKey,
            launchAtLoginEnabled: launchAtLoginEnabled,
            startTimerOnLaunch: startTimerOnLaunch
        )
        settingsStore.save(settings)
    }
}

@MainActor
final class ReminderPanelController {
    private weak var appState: AppState?
    private var panel: NSPanel?

    init(appState: AppState) {
        self.appState = appState
    }

    /// 关键流程：根据当前提醒强度计算面板像素尺寸，与 `ReminderFloatingView` 外框一致。
    private static func panelSize(for appState: AppState) -> NSSize {
        let i = appState.reminderIntensity
        return NSSize(width: i.panelWidth, height: i.panelHeight)
    }

    func show() {
        guard let appState else { return }
        if panel == nil {
            let size = Self.panelSize(for: appState)
            let newPanel = ReminderPanel(
                contentRect: NSRect(origin: .zero, size: size),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            newPanel.contentView = makeHostingView(appState: appState, size: size)
            newPanel.isOpaque = false
            newPanel.backgroundColor = .clear
            newPanel.hasShadow = true
            newPanel.level = .statusBar
            newPanel.hidesOnDeactivate = false
            newPanel.ignoresMouseEvents = false
            newPanel.isMovableByWindowBackground = true
            // 提醒浮窗需要跨桌面显示；canJoinAllSpaces 与 moveToActiveSpace 互斥，不能同时设置。
            newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            newPanel.isReleasedWhenClosed = false
            panel = newPanel
        }
        // 首次展示一轮提醒时回到默认位置；后续倒计时刷新不应覆盖用户拖动后的位置。
        refresh(reposition: true)
        // 用较高层级的独立面板前置，避免被 MenuBarExtra 菜单窗口吞掉。
        panel?.orderFrontRegardless()
        panel?.makeKey()
    }

    /// 关键流程：设置里切换提醒强度且弹窗正在显示时，同步窗口尺寸与圆角，避免只改内部视图而外框不变。
    func syncReminderPanelGeometryIfVisible(reposition: Bool = false) {
        guard let appState, appState.reminderPhase != .none else { return }
        refresh(reposition: reposition)
    }

    func refresh(reposition: Bool = false) {
        guard let appState, let panel else { return }
        let size = Self.panelSize(for: appState)
        // 透明 NSPanel 复用同一个 SwiftUI 图层时，阶段切换可能留下上一帧残影。
        // 这里直接重建 HostingView，让 AppKit 清空透明缓冲区后再绘制当前状态。
        panel.contentView = makeHostingView(appState: appState, size: size)
        applyPanelCornerMask()
        if reposition {
            positionAtTopCenter()
        } else {
            resizePreservingCenter(size)
        }
        panel.contentView?.needsDisplay = true
        panel.displayIfNeeded()
        panel.invalidateShadow()
    }

    func refreshDisplayOnly() {
        guard let panel else { return }
        panel.contentView?.needsDisplay = true
        panel.contentView?.subviews.forEach { $0.needsDisplay = true }
        panel.contentView?.layer?.setNeedsDisplay()
        panel.contentView?.layer?.displayIfNeeded()
        panel.displayIfNeeded()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func makeHostingView(appState: AppState, size: NSSize) -> NSView {
        let root = ReminderFloatingView()
            .environmentObject(appState)
            .frame(width: size.width, height: size.height)

        let hostingView = NSHostingView(rootView: root)
        hostingView.wantsLayer = true
        hostingView.layerContentsRedrawPolicy = .onSetNeedsDisplay
        hostingView.canDrawSubviewsIntoLayer = true
        hostingView.layer?.isOpaque = false
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        return hostingView
    }

    private func positionAtTopCenter() {
        guard let appState, let panel else { return }
        let size = Self.panelSize(for: appState)
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) }
            ?? NSScreen.main
            ?? NSScreen.screens.first
        guard let visibleFrame = screen?.visibleFrame else { return }
        let width = size.width
        let height = size.height
        let x = appState.reminderIntensity == .light
            ? visibleFrame.maxX - width - 24
            : visibleFrame.midX - width / 2
        let y = visibleFrame.maxY - height - (appState.reminderIntensity == .light ? 24 : 90)
        panel.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
    }

    private func resizePreservingCenter(_ size: NSSize) {
        guard let panel else { return }
        let current = panel.frame
        let x = current.midX - size.width / 2
        let y = current.midY - size.height / 2
        panel.setFrame(NSRect(x: x, y: y, width: size.width, height: size.height), display: true)
    }

    private func applyPanelCornerMask() {
        guard let appState, let panel, let contentView = panel.contentView else { return }
        contentView.wantsLayer = true
        contentView.layer?.cornerRadius = appState.reminderIntensity.cornerRadius
        contentView.layer?.cornerCurve = .continuous
        contentView.layer?.masksToBounds = true
    }
}

final class ReminderPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
