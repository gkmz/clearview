import AppKit
import SwiftUI
import Foundation

@main
struct ClearViewApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        // 关键流程：提供主窗口，确保首次运行时用户能直接看到界面。
        WindowGroup("ClearView") {
            ContentView()
                .environmentObject(appState)
                .background(WindowChromeConfigurator())
                .frame(minWidth: 480, minHeight: 350)
        }

        MenuBarExtra {
            ContentView()
                .environmentObject(appState)
                .frame(width: 480, height: 350)
        } label: {
            Label("ClearView", systemImage: "eye")
        }
        .menuBarExtraStyle(.window)
    }
}

struct WindowChromeConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            // 关键流程：让主窗口本身透明，圆角由 SwiftUI 内容层负责绘制。
            window.isOpaque = false
            window.backgroundColor = .clear
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.styleMask.insert(.fullSizeContentView)
            window.standardWindowButton(.closeButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

@MainActor
final class AppState: ObservableObject {
    enum ReminderPhase {
        case none
        case gentle
        case strong
        case final
    }

    @Published var reminderEnabled = true
    @Published var workIntervalMinutes: Int = 20
    @Published var breakDurationSeconds: Int = 20
    @Published var secondsUntilBreak: Int = 20 * 60
    @Published var filterLevel: BlueLightLevel = .off
    @Published var statusText: String = "运行中"
    @Published var reminderPhase: ReminderPhase = .none
    @Published var breakSecondsLeft: Int = 20

    let reminderService = ReminderService()
    let blueLightService = BlueLightFilterService()
    private var breakCountdownTimer: Timer?
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
        reminderPanel = ReminderPanelController(appState: self)
    }

    func toggleReminder(_ enabled: Bool) {
        reminderEnabled = enabled
        if enabled {
            reminderService.start(intervalMinutes: workIntervalMinutes)
            statusText = "提醒已开启"
        } else {
            reminderService.stop()
            statusText = "提醒已暂停"
        }
    }

    func updateInterval(_ minutes: Int) {
        workIntervalMinutes = max(1, minutes)
        if reminderEnabled {
            reminderService.start(intervalMinutes: workIntervalMinutes)
            statusText = "提醒间隔已更新"
        }
    }

    func updateBreakDuration(_ seconds: Int) {
        breakDurationSeconds = max(5, seconds)
        breakSecondsLeft = breakDurationSeconds
        statusText = "休息时长已更新"
    }

    func resetReminderTimer() {
        reminderEnabled = false
        reminderService.reset(intervalMinutes: workIntervalMinutes)
        statusText = "计时已重置"
    }

    func applyFilter(_ level: BlueLightLevel) {
        filterLevel = level
        // 关键流程：蓝光档位切换时立即应用到所有可用显示器。
        blueLightService.apply(level: level)
        statusText = "过滤档位：\(level.title)"
    }

    func triggerTestReminderNow() {
        startReminderFlow()
    }

    func triggerTestReminder(after seconds: Int) {
        let safeSeconds = max(1, seconds)
        statusText = "\(safeSeconds)秒后触发测试提醒"
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(safeSeconds)) { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.startReminderFlow()
            }
        }
    }

    func completeBreak() {
        endReminderFlow()
        statusText = "休息已完成"
        reminderService.start(intervalMinutes: workIntervalMinutes)
    }

    func skipBreak() {
        endReminderFlow()
        statusText = "已跳过本次提醒"
        reminderService.start(intervalMinutes: workIntervalMinutes)
    }

    func snoozeBreak(minutes: Int = 5) {
        endReminderFlow()
        statusText = "已推迟\(minutes)分钟"
        reminderService.snooze(minutes: minutes)
    }

    func quitApplication() {
        // 关键流程：退出前恢复显示色彩，避免蓝光过滤状态残留。
        blueLightService.apply(level: .off)
        NSApplication.shared.terminate(nil)
    }

    private func startReminderFlow() {
        // 关键流程：提醒到点时显示屏幕顶部居中的独立浮窗，避免只在菜单栏无感提示。
        reminderPhase = .gentle
        breakSecondsLeft = breakDurationSeconds
        statusText = "请开始休息"
        reminderPanel?.show()
        startBreakCountdown()

        // 关键流程：三段式提醒升级，10秒后增强提醒强度。
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                guard self.reminderPhase == .gentle else { return }
                self.reminderPhase = .strong
                self.statusText = "提醒升级：请尽快休息"
            }
        }

        // 关键流程：20秒仍未处理时进入兜底提醒（请求注意+蜂鸣）。
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                guard self.reminderPhase != .none else { return }
                self.reminderPhase = .final
                self.statusText = "强提醒：请完成休息"
                NSApplication.shared.requestUserAttention(.criticalRequest)
                NSSound.beep()
            }
        }
    }

    private func startBreakCountdown() {
        breakCountdownTimer?.invalidate()
        breakCountdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                guard self.reminderPhase != .none else { return }
                self.breakSecondsLeft -= 1
                if self.breakSecondsLeft <= 0 {
                    // 关键流程：休息倒计时结束后不自动关闭浮窗，等待用户点击继续按钮。
                    self.breakSecondsLeft = 0
                    self.statusText = "休息完成，点击继续"
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
                .frame(width: 420, height: 180)

            let hostingView = NSHostingView(rootView: root)
            hostingView.wantsLayer = true
            hostingView.layer?.backgroundColor = NSColor.clear.cgColor

            let newPanel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 420, height: 180),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            newPanel.contentView = hostingView
            newPanel.isOpaque = false
            newPanel.backgroundColor = .clear
            newPanel.hasShadow = true
            newPanel.level = .floating
            newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            newPanel.isReleasedWhenClosed = false
            panel = newPanel
        }

        positionAtTopCenter()
        // 关键流程：NSPanel 不需要成为 key window，直接前置显示可避免 canBecomeKeyWindow 警告。
        panel?.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func positionAtTopCenter() {
        guard let panel else { return }
        let screen = NSScreen.main?.visibleFrame ?? .zero
        let width: CGFloat = 420
        let height: CGFloat = 180
        let x = screen.midX - width / 2
        let y = screen.maxY - height - 24
        panel.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
    }
}
