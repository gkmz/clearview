import AppKit
import SwiftUI

@MainActor
final class MainPanelController {
    private weak var appState: AppState?
    private var panel: NSPanel?

    var frame: NSRect? {
        panel?.frame
    }

    var isVisible: Bool {
        panel?.isVisible == true
    }

    init(appState: AppState) {
        self.appState = appState
    }

    /// 显示主面板；启动时可保持窗口位于最前，避免首次展示后被其他应用覆盖。
    func show(keepFront: Bool = false) {
        guard let appState else { return }
        if panel == nil {
            panel = makePanel(appState: appState)
        }

        positionAtScreenCenter()
        NSApplication.shared.activate(ignoringOtherApps: true)
        // 打开瞬间临时前置，确保窗口不会在创建后闪现再被其他应用覆盖。
        panel?.level = .floating
        panel?.orderFrontRegardless()
        panel?.makeKeyAndOrderFront(nil)
        panel?.makeKey()
        guard !keepFront else { return }
        DispatchQueue.main.async { [weak panel] in
            // 普通入口恢复标准层级，避免用户从菜单栏打开面板后长期遮挡其他应用。
            panel?.level = .normal
        }
    }

    func toggle() {
        if panel?.isVisible == true {
            hide()
        } else {
            show()
        }
    }

    func hide() {
        panel?.orderOut(nil)
    }

    func setMovableByBackground(_ isMovable: Bool) {
        panel?.isMovableByWindowBackground = isMovable
    }

    private func makePanel(appState: AppState) -> NSPanel {
        let root = ContentView()
            .environmentObject(appState)
            .frame(width: 920, height: 540)

        let hostingView = NSHostingView(rootView: root)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor

        let panel = MainPanel(
            contentRect: NSRect(x: 0, y: 0, width: 920, height: 540),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // 主界面改由自定义透明面板承载，菜单栏只作为快捷入口。
        panel.contentView = hostingView
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .normal
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = false
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        return panel
    }

    private func positionAtScreenCenter() {
        guard let panel else { return }
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) }
            ?? NSScreen.main
            ?? NSScreen.screens.first
        guard let visibleFrame = screen?.visibleFrame else { return }

        let width: CGFloat = 920
        let height: CGFloat = 540
        let x = visibleFrame.midX - width / 2
        let y = visibleFrame.midY - height / 2
        panel.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
    }
}

final class MainPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
