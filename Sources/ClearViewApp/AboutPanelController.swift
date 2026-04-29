import AppKit
import SwiftUI

@MainActor
final class AboutPanelController {
    private weak var appState: AppState?
    private var panel: NSPanel?
    private let panelSize = NSSize(width: 920, height: 540)

    init(appState: AppState) {
        self.appState = appState
    }

    func show(anchoredTo frame: NSRect?) {
        guard let appState else { return }
        if panel == nil {
            panel = makePanel(appState: appState)
        }

        position(anchoredTo: frame)
        NSApplication.shared.activate(ignoringOtherApps: true)
        panel?.orderFrontRegardless()
        panel?.makeKey()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func makePanel(appState: AppState) -> NSPanel {
        let root = AboutPanelView()
            .environmentObject(appState)
            .frame(width: panelSize.width, height: panelSize.height)

        let hostingView = NSHostingView(rootView: root)
        hostingView.wantsLayer = true
        hostingView.layer?.isOpaque = false
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor

        let panel = AboutPanel(
            contentRect: NSRect(origin: .zero, size: panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // 关键流程：关于窗和设置窗一样独立承载，避免弹出时影响主界面背景合成。
        panel.contentView = hostingView
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = false
        panel.isMovableByWindowBackground = false
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        return panel
    }

    private func position(anchoredTo frame: NSRect?) {
        guard let panel else { return }
        if let frame {
            panel.setFrame(frame, display: true)
            return
        }

        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) }
            ?? NSScreen.main
            ?? NSScreen.screens.first
        guard let visibleFrame = screen?.visibleFrame else { return }
        let x = visibleFrame.midX - panelSize.width / 2
        let y = visibleFrame.midY - panelSize.height / 2
        panel.setFrame(NSRect(x: x, y: y, width: panelSize.width, height: panelSize.height), display: true)
    }
}

final class AboutPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

private struct AboutPanelView: View {
    @EnvironmentObject private var appState: AppState
    @State private var titleReveal: CGFloat = 0
    @State private var shineOffset: CGFloat = -1.2
    @State private var isTitleRevealed = false
    @State private var isShineVisible = false

    private var textPrimary: Color { Color.white.opacity(0.96) }
    private var textSecondary: Color { Color.white.opacity(0.74) }
    private var buttonTint: Color { Color.white.opacity(0.20) }
    private var buttonBorder: Color { Color.white.opacity(0.22) }
    private var panelFill: Color {
        // 关键流程：关于窗复用设置窗透明度，100% 时保持完全不透明。
        Color.black.opacity(appState.settingsWindowOpacity)
    }

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    appState.hideAboutPanel()
                }

            ZStack(alignment: .topTrailing) {
                Button {
                    appState.hideAboutPanel()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 30, height: 30)
                        .foregroundStyle(textSecondary)
                        .background(Color.clear)
                        .modifier(AboutGlassButtonModifier(cornerRadius: 15, intensity: 1.0, tint: buttonTint, border: buttonBorder))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .focusable(false)
                .hoverTooltip("关闭关于")
                .zIndex(1)

                VStack(spacing: 14) {
                    animatedTitle

                    Text("版本 \(AppVersion.version)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(textSecondary)

                    Text("Copyright © 2026 ClearView")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.46))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 28)
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
            .frame(width: 390)
            .background(panelFill)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.12),
                                Color.white.opacity(0.04),
                                Color.black.opacity(0.12)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .allowsHitTesting(false)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.30), lineWidth: 1)
                    .allowsHitTesting(false)
            )
            .shadow(color: .black.opacity(0.18), radius: 24, x: 0, y: 14)
        }
        .onAppear {
            // 关键流程：先揭示标题，再用 45 度高光扫过，最后回到完整纯白文字。
            titleReveal = 0
            shineOffset = -1.2
            isTitleRevealed = false
            isShineVisible = false

            withAnimation(.easeOut(duration: 0.90).delay(0.08)) {
                titleReveal = 1
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.00) {
                isTitleRevealed = true
                isShineVisible = true
                withAnimation(.easeInOut(duration: 1.18)) {
                    shineOffset = 1.2
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.30) {
                isShineVisible = false
            }
        }
    }

    private var animatedTitle: some View {
        let title = Text("ClearView，让眼睛学会放松。")
            .font(.system(size: 24, weight: .semibold))
            .tracking(0.4)
            .lineLimit(1)

        return ZStack {
            if isTitleRevealed {
                title
                    .foregroundStyle(textPrimary)
            } else {
                title
                    .foregroundStyle(textPrimary)
                    .mask(alignment: .leading) {
                        Rectangle()
                            .frame(width: 330 * titleReveal)
                    }
                    .opacity(0.56 + 0.44 * titleReveal)
            }

            if isShineVisible {
                ZStack {
                    title
                        .foregroundStyle(Color.white)

                    title
                        .foregroundStyle(Color.white)
                        .blur(radius: 1.8)
                }
                .opacity(0.95)
                .mask {
                    ZStack {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.clear,
                                        Color.white.opacity(0.35),
                                        Color.white,
                                        Color.white.opacity(0.35),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 76)
                            .rotationEffect(.degrees(45))
                            .offset(x: shineOffset * 310)
                    }
                }
                .shadow(color: .white.opacity(0.32), radius: 8, x: 0, y: 0)
                .allowsHitTesting(false)
            }
        }
        .frame(height: 34)
    }
}

private struct AboutGlassButtonModifier: ViewModifier {
    let cornerRadius: CGFloat
    let intensity: CGFloat
    let tint: Color
    let border: Color
    @State private var isHovering = false

    func body(content: Content) -> some View {
        let fillOpacity = (isHovering ? 0.18 : 0.10) * intensity
        let highlightOpacity = (isHovering ? 0.32 : 0.22) * intensity
        let borderOpacity = (isHovering ? 0.52 : 0.38) * intensity

        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(tint.opacity(fillOpacity))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(highlightOpacity),
                                Color.white.opacity(highlightOpacity * 0.36),
                                Color.black.opacity(0.03 * intensity)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .allowsHitTesting(false)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(border.opacity(borderOpacity), lineWidth: 1)
            )
            .scaleEffect(isHovering ? 1.025 : 1.0)
            .offset(y: isHovering ? -1 : 0)
            .animation(.easeOut(duration: 0.16), value: isHovering)
            .onHover { hovering in
                isHovering = hovering
            }
    }
}
