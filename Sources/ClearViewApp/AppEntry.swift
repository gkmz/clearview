import AppKit
import SwiftUI
import Foundation

@main
struct ClearViewApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
        } label: {
            Label("ClearView", systemImage: "eye")
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    enum ReminderPhase {
        case none
        case preparing
        case resting
        case completed
    }

    @Published var reminderEnabled = true
    @Published var workIntervalMinutes: Int = 20
    @Published var breakDurationSeconds: Int = 20
    @Published var secondsUntilBreak: Int = 20 * 60
    @Published var filterLevel: BlueLightLevel = .off
    @Published var useBackgroundImage = true
    @Published var playBreakFinishedSound = false
    @Published var shortcutKeyCode: UInt16 = 49
    @Published var shortcutModifierFlagsRaw: UInt = 1_179_648
    @Published var reminderToggleShortcutKeyCode: UInt16 = 35
    @Published var reminderToggleShortcutModifierFlagsRaw: UInt = 1_179_648
    @Published var cycleFilterShortcutKeyCode: UInt16 = 37
    @Published var cycleFilterShortcutModifierFlagsRaw: UInt = 1_179_648
    @Published var backgroundImageOpacity: Double = 1.0
    @Published var mainWindowOpacity: Double = 0.80
    @Published var reminderWindowOpacity: Double = 0.78
    @Published var statusText: String = "陪你护眼"
    @Published var reminderPhase: ReminderPhase = .none
    @Published var breakSecondsLeft: Int = 20

    let reminderService = ReminderService()
    let blueLightService = BlueLightFilterService()
    private let shortcutManager = GlobalShortcutManager.shared
    private let settingsStore = AppSettingsStore()
    private let preparationSeconds = 5
    private var breakCountdownTimer: Timer?
    private var mainPanel: MainPanelController?
    private var reminderPanel: ReminderPanelController?

    init() {
        loadSettings()

        reminderService.onTick = { [weak self] secondsLeft in
            guard let self else { return }
            Task { @MainActor in
                self.secondsUntilBreak = secondsLeft
            }
        }

        reminderService.onBreakTriggered = { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.startReminderFlow()
            }
        }

        if reminderEnabled {
            reminderService.start(intervalMinutes: workIntervalMinutes)
        } else {
            reminderService.stop()
        }
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
                self.toggleReminder(!self.reminderEnabled)
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
        if !mainPanelShortcutRegistered {
            statusText = "主界面快捷键注册失败，请在设置中重新选择"
        } else if !reminderToggleShortcutRegistered {
            statusText = "暂停提醒快捷键注册失败，请在设置中重新选择"
        } else if !cycleFilterShortcutRegistered {
            statusText = "护眼模式快捷键注册失败，请在设置中重新选择"
        }
        mainPanel = MainPanelController(appState: self)
        reminderPanel = ReminderPanelController(appState: self)
    }

    func showMainPanel() {
        mainPanel?.show()
    }

    func toggleMainPanel() {
        mainPanel?.toggle()
    }

    func hideMainPanel() {
        mainPanel?.hide()
    }

    func setMainPanelMovableByBackground(_ isMovable: Bool) {
        mainPanel?.setMovableByBackground(isMovable)
    }

    func toggleReminder(_ enabled: Bool) {
        reminderEnabled = enabled
        if enabled {
            reminderService.start(intervalMinutes: workIntervalMinutes)
            statusText = "会按时提醒你"
        } else {
            reminderService.stop()
            statusText = "先不打扰"
        }
        persistSettings()
    }

    func updateInterval(_ minutes: Int) {
        workIntervalMinutes = max(1, minutes)
        if reminderEnabled {
            reminderService.start(intervalMinutes: workIntervalMinutes)
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

    func resetReminderTimer() {
        reminderEnabled = false
        reminderService.reset(intervalMinutes: workIntervalMinutes)
        statusText = "重新开始"
        persistSettings()
    }

    func applyFilter(_ level: BlueLightLevel) {
        filterLevel = level
        // 关键流程：蓝光档位切换时立即应用到所有可用显示器。
        blueLightService.apply(level: level)
        statusText = "护眼：\(level.title)"
        persistSettings()
    }

    func updateBackgroundImageEnabled(_ enabled: Bool) {
        useBackgroundImage = enabled
        // 关键流程：无背景图时保留最低底色，避免主界面完全透明后文字失去承托。
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

    func updateShortcut(action: ShortcutAction, keyCode: UInt16, modifierFlagsRaw: UInt) {
        // 关键流程：普通按键至少需要一个修饰键；F1-F20 这类功能键允许单独作为全局快捷键。
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
        // 关键流程：有背景图时允许底色完全透明；无背景图时保留最低底色保证可读性。
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
        // 关键流程：提示窗透明度单独可调，兼顾提醒可见性与通透感。
        reminderWindowOpacity = min(max(value, 0.25), 1.0)
        statusText = "提示窗透明度已调整"
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
        startReminderFlow()
    }

    func triggerTestReminder(after seconds: Int) {
        let safeSeconds = max(1, seconds)
        statusText = "\(safeSeconds)秒后提醒你"
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(safeSeconds)) { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.startReminderFlow()
            }
        }
    }

    func completeBreak() {
        endReminderFlow()
        statusText = AppCopy.Status.finished
        reminderService.start(intervalMinutes: workIntervalMinutes)
    }

    func skipBreak() {
        endReminderFlow()
        statusText = "先继续也可以"
        reminderService.start(intervalMinutes: workIntervalMinutes)
    }

    func snoozeBreak(minutes: Int = 5) {
        endReminderFlow()
        statusText = "\(minutes)分钟后再提醒"
        reminderService.snooze(minutes: minutes)
    }

    func quitApplication() {
        // 关键流程：退出前恢复显示色彩，避免蓝光过滤状态残留。
        blueLightService.apply(level: .off)
        NSApplication.shared.terminate(nil)
    }

    private func startReminderFlow() {
        // 关键流程：先给用户 5 秒反应时间，再进入正式休息倒计时。
        reminderPhase = .preparing
        breakSecondsLeft = preparationSeconds
        statusText = AppCopy.Status.preparing
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
                    self.reminderPhase = .resting
                    self.breakSecondsLeft = self.breakDurationSeconds
                    self.statusText = AppCopy.Status.resting
                    self.reminderPanel?.refresh()
                    self.breakCountdownTimer?.invalidate()
                    self.breakCountdownTimer = nil
                    self.startBreakCountdown()
                } else {
                    // 关键流程：倒计时过程中仅触发重绘，不重建 SwiftUI 视图，兼顾去重影与悬停提示稳定性。
                    self.reminderPanel?.refreshDisplayOnly()
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
                guard self.reminderPhase == .resting else { return }
                self.breakSecondsLeft -= 1
                if self.breakSecondsLeft <= 0 {
                    // 关键流程：休息倒计时结束后不自动关闭浮窗，等待用户点击继续按钮。
                    self.reminderPhase = .completed
                    self.breakSecondsLeft = 0
                    self.statusText = AppCopy.Status.completed
                    self.reminderPanel?.refresh()
                    if self.playBreakFinishedSound {
                        // 关键流程：用户可能正在看远方，结束时可选用短促声音温柔提醒可以回来了。
                        self.playBreakFinishedSoundEffect()
                    }
                    self.breakCountdownTimer?.invalidate()
                    self.breakCountdownTimer = nil
                } else {
                    // 关键流程：每秒数字变化后请求窗口重绘，清理透明面板上的旧帧残留。
                    self.reminderPanel?.refreshDisplayOnly()
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
        workIntervalMinutes = max(1, settings.workIntervalMinutes)
        breakDurationSeconds = max(5, settings.breakDurationSeconds)
        filterLevel = BlueLightLevel.fromSettingsKey(settings.filterLevelKey)
        useBackgroundImage = settings.useBackgroundImage
        playBreakFinishedSound = settings.playBreakFinishedSound
        shortcutKeyCode = settings.shortcutToggleMainPanelKeyCode
        shortcutModifierFlagsRaw = settings.shortcutToggleMainPanelModifierFlagsRaw
        reminderToggleShortcutKeyCode = settings.shortcutToggleReminderKeyCode
        reminderToggleShortcutModifierFlagsRaw = settings.shortcutToggleReminderModifierFlagsRaw
        cycleFilterShortcutKeyCode = settings.shortcutCycleBlueLightLevelKeyCode
        cycleFilterShortcutModifierFlagsRaw = settings.shortcutCycleBlueLightLevelModifierFlagsRaw
        backgroundImageOpacity = min(max(settings.backgroundImageOpacity, 0.25), 1.0)
        mainWindowOpacity = normalizedMainWindowOpacity(settings.mainWindowOpacity, useBackgroundImage: useBackgroundImage)
        reminderWindowOpacity = min(max(settings.reminderWindowOpacity, 0.25), 1.0)

        // 关键流程：应用启动时恢复倒计时基础值，避免界面显示与配置不一致。
        secondsUntilBreak = workIntervalMinutes * 60
        breakSecondsLeft = breakDurationSeconds

        // 关键流程：启动时恢复上次蓝光档位，让视觉状态连续。
        blueLightService.apply(level: filterLevel)
    }

    private func normalizedMainWindowOpacity(_ value: Double, useBackgroundImage: Bool) -> Double {
        let minimumOpacity = useBackgroundImage ? 0.0 : 0.20
        return min(max(value, minimumOpacity), 1.0)
    }

    private func persistSettings() {
        let settings = AppSettings(
            reminderEnabled: reminderEnabled,
            workIntervalMinutes: workIntervalMinutes,
            breakDurationSeconds: breakDurationSeconds,
            filterLevelKey: filterLevel.settingsKey,
            useBackgroundImage: useBackgroundImage,
            playBreakFinishedSound: playBreakFinishedSound,
            shortcutKeyCode: shortcutKeyCode,
            shortcutModifierFlagsRaw: shortcutModifierFlagsRaw,
            shortcutToggleMainPanelKeyCode: shortcutKeyCode,
            shortcutToggleMainPanelModifierFlagsRaw: shortcutModifierFlagsRaw,
            shortcutToggleReminderKeyCode: reminderToggleShortcutKeyCode,
            shortcutToggleReminderModifierFlagsRaw: reminderToggleShortcutModifierFlagsRaw,
            shortcutCycleBlueLightLevelKeyCode: cycleFilterShortcutKeyCode,
            shortcutCycleBlueLightLevelModifierFlagsRaw: cycleFilterShortcutModifierFlagsRaw,
            backgroundImageOpacity: backgroundImageOpacity,
            mainWindowOpacity: mainWindowOpacity,
            reminderWindowOpacity: reminderWindowOpacity
        )
        settingsStore.save(settings)
    }
}

@MainActor
final class ReminderPanelController {
    private weak var appState: AppState?
    private var panel: NSPanel?
    private let panelSize = NSSize(width: 560, height: 300)

    init(appState: AppState) {
        self.appState = appState
    }

    func show() {
        guard let appState else { return }
        if panel == nil {
            let newPanel = ReminderPanel(
                contentRect: NSRect(origin: .zero, size: panelSize),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            newPanel.contentView = makeHostingView(appState: appState)
            newPanel.isOpaque = false
            newPanel.backgroundColor = .clear
            newPanel.hasShadow = true
            newPanel.level = .statusBar
            newPanel.hidesOnDeactivate = false
            newPanel.ignoresMouseEvents = false
            newPanel.isMovableByWindowBackground = true
            // 关键流程：提醒浮窗需要跨桌面显示；canJoinAllSpaces 与 moveToActiveSpace 互斥，不能同时设置。
            newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            newPanel.isReleasedWhenClosed = false
            panel = newPanel
        } else {
            refresh()
        }

        positionAtTopCenter()
        applyPanelCornerMask()
        // 关键流程：用较高层级的独立面板前置，避免被 MenuBarExtra 菜单窗口吞掉。
        panel?.orderFrontRegardless()
        panel?.makeKey()
    }

    func refresh() {
        guard let appState, let panel else { return }
        // 关键流程：透明 NSPanel 复用同一个 SwiftUI 图层时，阶段切换可能留下上一帧残影。
        // 这里直接重建 HostingView，让 AppKit 清空透明缓冲区后再绘制当前状态。
        panel.contentView = makeHostingView(appState: appState)
        applyPanelCornerMask()
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

    private func makeHostingView(appState: AppState) -> NSView {
        let root = ReminderFloatingView()
            .environmentObject(appState)
            .frame(width: panelSize.width, height: panelSize.height)

        let hostingView = NSHostingView(rootView: root)
        hostingView.wantsLayer = true
        hostingView.layerContentsRedrawPolicy = .onSetNeedsDisplay
        hostingView.canDrawSubviewsIntoLayer = true
        hostingView.layer?.isOpaque = false
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        return hostingView
    }

    private func positionAtTopCenter() {
        guard let panel else { return }
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) }
            ?? NSScreen.main
            ?? NSScreen.screens.first
        guard let visibleFrame = screen?.visibleFrame else { return }
        let width = panelSize.width
        let height = panelSize.height
        let x = visibleFrame.midX - width / 2
        // 关键流程：放大后的提示窗仍保持顶部居中，并留出呼吸空间避免贴近菜单栏。
        let y = visibleFrame.maxY - height - 90
        panel.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
    }

    private func applyPanelCornerMask() {
        guard let panel, let contentView = panel.contentView else { return }
        contentView.wantsLayer = true
        contentView.layer?.cornerRadius = 20
        contentView.layer?.cornerCurve = .continuous
        contentView.layer?.masksToBounds = true
    }
}

final class ReminderPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
