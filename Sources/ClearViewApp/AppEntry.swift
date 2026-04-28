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
    @Published var statusText: String = "陪你护眼"
    @Published var reminderPhase: ReminderPhase = .none
    @Published var breakSecondsLeft: Int = 20

    let reminderService = ReminderService()
    let blueLightService = BlueLightFilterService()
    private let preparationSeconds = 5
    private var breakCountdownTimer: Timer?
    private var mainPanel: MainPanelController?
    private var reminderPanel: ReminderPanelController?

    init() {
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

        reminderService.start(intervalMinutes: workIntervalMinutes)
        mainPanel = MainPanelController(appState: self)
        reminderPanel = ReminderPanelController(appState: self)
    }

    func showMainPanel() {
        mainPanel?.show()
    }

    func toggleMainPanel() {
        mainPanel?.toggle()
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
    }

    func updateInterval(_ minutes: Int) {
        workIntervalMinutes = max(1, minutes)
        if reminderEnabled {
            reminderService.start(intervalMinutes: workIntervalMinutes)
            statusText = "节奏已调整"
        }
    }

    func updateBreakDuration(_ seconds: Int) {
        breakDurationSeconds = max(5, seconds)
        breakSecondsLeft = breakDurationSeconds
        statusText = "休息时间已调整"
    }

    func resetReminderTimer() {
        reminderEnabled = false
        reminderService.reset(intervalMinutes: workIntervalMinutes)
        statusText = "重新开始"
    }

    func applyFilter(_ level: BlueLightLevel) {
        filterLevel = level
        // 关键流程：蓝光档位切换时立即应用到所有可用显示器。
        blueLightService.apply(level: level)
        statusText = "护眼：\(level.title)"
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
        statusText = "眼睛放松好了"
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
        statusText = "准备放松眼睛"
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
                    self.statusText = "看看远方吧"
                    self.breakCountdownTimer?.invalidate()
                    self.breakCountdownTimer = nil
                    self.startBreakCountdown()
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
                    self.statusText = "休息好了"
                    // 关键流程：用户可能正在看远方，结束时用短促声音温柔提醒可以回来了。
                    self.playBreakFinishedSound()
                    self.breakCountdownTimer?.invalidate()
                    self.breakCountdownTimer = nil
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

    private func playBreakFinishedSound() {
        NSSound(named: "Glass")?.play()
    }
}

@MainActor
final class ReminderPanelController {
    private weak var appState: AppState?
    private var panel: NSPanel?

    init(appState: AppState) {
        self.appState = appState
    }

    func show() {
        guard let appState else { return }
        if panel == nil {
            let root = ReminderFloatingView()
                .environmentObject(appState)
                .frame(width: 420, height: 210)

            let hostingView = NSHostingView(rootView: root)
            hostingView.wantsLayer = true
            hostingView.layer?.backgroundColor = NSColor.clear.cgColor

            let newPanel = ReminderPanel(
                contentRect: NSRect(x: 0, y: 0, width: 420, height: 210),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            newPanel.contentView = hostingView
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
        }

        positionAtTopCenter()
        // 关键流程：用较高层级的独立面板前置，避免被 MenuBarExtra 菜单窗口吞掉。
        panel?.orderFrontRegardless()
        panel?.makeKey()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func positionAtTopCenter() {
        guard let panel else { return }
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) }
            ?? NSScreen.main
            ?? NSScreen.screens.first
        guard let visibleFrame = screen?.visibleFrame else { return }
        let width: CGFloat = 420
        let height: CGFloat = 210
        let x = visibleFrame.midX - width / 2
        // 关键流程：提示窗顶部留出约 80px，不贴菜单栏，减少压迫感。
        let y = visibleFrame.maxY - height - 80
        panel.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
    }
}

final class ReminderPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
