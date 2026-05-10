import AppKit
import SwiftUI

@MainActor
final class SettingsPanelController {
    private weak var appState: AppState?
    private var panel: NSPanel?
    private let panelSize = NSSize(width: 920, height: 540)

    init(appState: AppState) {
        self.appState = appState
    }

    func toggle(anchoredTo frame: NSRect?) {
        if panel?.isVisible == true {
            hide()
        } else {
            show(anchoredTo: frame)
        }
    }

    func show(anchoredTo frame: NSRect?) {
        guard let appState else { return }
        if panel == nil {
            panel = makePanel(appState: appState)
        }

        position(anchoredTo: frame)
        panel?.orderFrontRegardless()
        panel?.makeKey()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func makePanel(appState: AppState) -> NSPanel {
        let root = SettingsPanelView()
            .environmentObject(appState)
            .frame(width: panelSize.width, height: panelSize.height)

        let hostingView = NSHostingView(rootView: root)
        hostingView.wantsLayer = true
        hostingView.layer?.isOpaque = false
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor

        let panel = SettingsPanel(
            contentRect: NSRect(origin: .zero, size: panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // 设置窗独立于主界面渲染，打开/关闭时不再触发主界面背景重新合成。
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

final class SettingsPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

private struct SettingsPanelView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var recordingShortcutAction: ShortcutAction?
    @State private var shortcutRecordMonitor: Any?
    @State private var isRhythmSettingsExpanded = true
    @State private var isAppearanceSettingsExpanded = false
    @State private var isPreferenceSettingsExpanded = false
    @State private var settingsContentHeight: CGFloat = 0

    private var isDark: Bool { colorScheme == .dark }
    private var textPrimary: Color { Color.white.opacity(0.96) }
    private var textSecondary:
     Color { Color.white.opacity(0.78) }
    private var buttonTint: Color { Color.white.opacity(0.20) }
    private var buttonBorder: Color { Color.white.opacity(0.22) }
    private var panelFill: Color {
        // 设置为 100% 时必须真正不透明，避免滑杆语义和视觉效果不一致。
        Color.black.opacity(appState.settingsWindowOpacity)
    }

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    appState.hideSettingsPanel()
                }

            GeometryReader { proxy in
                // 设置窗随内容增减自然伸缩，但整体高度不能超过主界面上下留白后的可用高度。
                let verticalMargin: CGFloat = 48
                let modalChromeHeight: CGFloat = 80
                let maxModalHeight = max(proxy.size.height - verticalMargin * 2, 260)
                let maxContentHeight = max(maxModalHeight - modalChromeHeight, 160)

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("小设置")
                            .font(.headline)
                            .foregroundStyle(textPrimary)
                        Spacer()
                        Button {
                            appState.hideSettingsPanel()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .semibold))
                                .frame(width: 30, height: 30)
                                .foregroundStyle(textSecondary)
                                .background(Color.clear)
                                .modifier(SettingsGlassButtonModifier(cornerRadius: 15, intensity: 1.0, tint: buttonTint, border: buttonBorder))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .focusable(false)
                        .hoverTooltip("收起设置")
                    }

                    ScrollView(.vertical, showsIndicators: settingsContentHeight > maxContentHeight) {
                        settingsSectionsContent
                    }
                    .frame(maxHeight: maxContentHeight)
                    // 内容未超高时按自然高度收缩；超高时由 maxHeight 截断并启用滚动。
                    .fixedSize(horizontal: false, vertical: true)
                    .onPreferenceChange(SettingsPanelContentHeightKey.self) { height in
                        settingsContentHeight = height
                    }
                }
                .padding(18)
                .frame(width: 340)
                .frame(maxHeight: maxModalHeight)
                .fixedSize(horizontal: false, vertical: true)
                .background(panelFill)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
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
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.30), lineWidth: 1)
                        .allowsHitTesting(false)
                )
                .overlay(alignment: .top) {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white.opacity(0.16))
                        .frame(height: 1)
                        .padding(.horizontal, 14)
                        .allowsHitTesting(false)
                }
                .shadow(color: .black.opacity(0.18), radius: 24, x: 0, y: 14)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .onDisappear {
            stopShortcutRecording()
        }
    }

    private var settingsSectionsContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            settingsSection(title: "节奏", isExpanded: $isRhythmSettingsExpanded) {
                rhythmModeRow()

                presetRow(
                    title: "护眼间隔",
                    values: [20, 25, 45, 60],
                    unit: "分钟",
                    selected: appState.workIntervalMinutes
                ) { appState.updateInterval($0) }

                presetRow(
                    title: "舒眼多久",
                    values: [20, 40, 60, 90],
                    unit: "秒",
                    selected: appState.breakDurationSeconds
                ) { appState.updateBreakDuration($0) }

                if appState.rhythmMode == .pomodoro {
                    presetRow(
                        title: "专注多久",
                        values: [25, 45, 50, 60],
                        unit: "分钟",
                        selected: appState.pomodoroFocusMinutes
                    ) { appState.updatePomodoroFocus($0) }

                    presetRow(
                        title: "番茄休息",
                        values: [5, 10, 15, 20],
                        unit: "分钟",
                        selected: appState.pomodoroBreakMinutes
                    ) { appState.updatePomodoroBreak($0) }

                    settingToggleCard(
                        title: "番茄中舒眼",
                        isOn: Binding(
                            get: { appState.pomodoroEyeBreakEnabled },
                            set: { appState.updatePomodoroEyeBreakEnabled($0) }
                        )
                    )
                }
            }

            settingsSection(title: "外观", isExpanded: $isAppearanceSettingsExpanded) {
                HStack(spacing: 10) {
                    settingToggleCard(
                        title: "背景图片",
                        isOn: Binding(
                            get: { appState.useBackgroundImage },
                            set: { appState.updateBackgroundImageEnabled($0) }
                        )
                    )
                }

                if appState.useBackgroundImage {
                    opacitySettingRow(
                        title: "背景图透明度",
                        value: Binding(
                            get: { appState.backgroundImageOpacity },
                            set: { appState.updateBackgroundImageOpacity($0) }
                        )
                    )
                }

                opacitySettingRow(
                    title: "主界面透明度",
                    value: Binding(
                        get: { appState.mainWindowOpacity },
                        set: { appState.updateMainWindowOpacity($0) }
                    ),
                    range: appState.useBackgroundImage ? 0.0...1.0 : 0.20...1.0
                )

                // 关键流程：轻/中/重控制提醒面板尺寸与字号，对应不同「需要被提醒」的程度。
                reminderIntensityRow()

                opacitySettingRow(
                    title: "提示窗透明度",
                    value: Binding(
                        get: { appState.reminderWindowOpacity },
                        set: { appState.updateReminderWindowOpacity($0) }
                    )
                )

                opacitySettingRow(
                    title: "设置/关于窗透明度",
                    value: Binding(
                        get: { appState.settingsWindowOpacity },
                        set: { appState.updateSettingsWindowOpacity($0) }
                    )
                )
            }

            settingsSection(title: "偏好", isExpanded: $isPreferenceSettingsExpanded) {
                HStack(spacing: 10) {
                    settingToggleCard(
                        title: "结束提示音",
                        isOn: Binding(
                            get: { appState.playBreakFinishedSound },
                            set: { appState.updateBreakFinishedSoundEnabled($0) }
                        )
                    )
                }

                shortcutSettingCard
            }
        }
        .background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: SettingsPanelContentHeightKey.self, value: proxy.size.height)
            }
        )
    }

    private func settingsSection<Content: View>(
        title: String,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let toggleSection = {
            withAnimation(.easeInOut(duration: 0.18)) {
                isExpanded.wrappedValue.toggle()
            }
        }

        return VStack(alignment: .leading, spacing: isExpanded.wrappedValue ? 10 : 0) {
            Button {
                toggleSection()
            } label: {
                HStack {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(textSecondary)
                        .rotationEffect(.degrees(isExpanded.wrappedValue ? 0 : -90))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 1)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .focusable(false)

            if isExpanded.wrappedValue {
                VStack(alignment: .leading, spacing: 10) {
                    content()
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        // 折叠状态下整张小标题卡片都可点击，避免只能点文字行。
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture {
            if !isExpanded.wrappedValue {
                toggleSection()
            }
        }
    }

    private func reminderIntensityRow() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Text("提醒强度")
                    .font(.caption)
                    .foregroundStyle(textPrimary)
                Spacer()
                Text(appState.reminderIntensity.title)
                    .font(.caption)
                    .foregroundStyle(textSecondary.opacity(0.88))
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
                    .frame(maxWidth: 160, alignment: .trailing)
            }

            HStack(spacing: 8) {
                ForEach(ReminderIntensityLevel.allCases, id: \.self) { level in
                    let isSelected = appState.reminderIntensity == level
                    Button {
                        appState.updateReminderIntensity(level)
                    } label: {
                        Text(level.shortTitle)
                            .font(.caption.weight(isSelected ? .bold : .semibold))
                            .frame(width: 56, height: 28)
                            .foregroundStyle(isSelected ? Color.white : textPrimary)
                            .background(isSelected ? Color.white.opacity(isDark ? 0.34 : 0.30) : Color.clear)
                            .modifier(
                                SettingsGlassButtonModifier(
                                    cornerRadius: 14,
                                    intensity: isSelected ? 0.60 : 1.0,
                                    tint: buttonTint,
                                    border: isSelected ? Color.white.opacity(0.50) : buttonBorder
                                )
                            )
                            .scaleEffect(isSelected ? 1.04 : 1.0)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                    .hoverTooltip(level.title)
                }
            }
        }
    }

    private func rhythmModeRow() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("节奏模式")
                    .font(.caption)
                    .foregroundStyle(textPrimary)
                Spacer()
                Text(appState.rhythmMode.title)
                    .font(.caption)
                    .foregroundStyle(textSecondary.opacity(0.92))
            }

            HStack(spacing: 8) {
                ForEach(RhythmMode.allCases, id: \.self) { mode in
                    let isSelected = appState.rhythmMode == mode
                    Button {
                        appState.updateRhythmMode(mode)
                    } label: {
                        Text(mode.title)
                            .font(.caption.weight(isSelected ? .bold : .semibold))
                            .frame(width: 76, height: 28)
                            .foregroundStyle(isSelected ? Color.white : textPrimary)
                            .background(isSelected ? Color.white.opacity(isDark ? 0.34 : 0.30) : Color.clear)
                            .modifier(
                                SettingsGlassButtonModifier(
                                    cornerRadius: 14,
                                    intensity: isSelected ? 0.60 : 1.0,
                                    tint: buttonTint,
                                    border: isSelected ? Color.white.opacity(0.50) : buttonBorder
                                )
                            )
                            .scaleEffect(isSelected ? 1.04 : 1.0)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                    .hoverTooltip(mode.statusTitle)
                }
            }
        }
    }

    private func presetRow(
        title: String,
        values: [Int],
        unit: String,
        selected: Int,
        onSelect: @escaping (Int) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(textPrimary)
                Spacer()
                Text("\(selected)\(unit)")
                    .font(.caption)
                    .foregroundStyle(textSecondary.opacity(0.92))
            }

            HStack(spacing: 8) {
                ForEach(values, id: \.self) { value in
                    let isSelected = selected == value
                    Button {
                        onSelect(value)
                    } label: {
                        Text("\(value)")
                            .font(.caption.weight(isSelected ? .bold : .semibold))
                            .frame(width: 48, height: 28)
                            .foregroundStyle(isSelected ? Color.white : textPrimary)
                            .background(isSelected ? Color.white.opacity(isDark ? 0.34 : 0.30) : Color.clear)
                            .modifier(
                                SettingsGlassButtonModifier(
                                    cornerRadius: 14,
                                    intensity: isSelected ? 0.60 : 1.0,
                                    tint: buttonTint,
                                    border: isSelected ? Color.white.opacity(0.50) : buttonBorder
                                )
                            )
                            .scaleEffect(isSelected ? 1.04 : 1.0)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                    .hoverTooltip("\(value)\(unit)")
                }
            }
        }
    }

    private func opacitySettingRow(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double> = 0.25...1.0
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(textPrimary)
                Spacer()
                Text("\(Int(value.wrappedValue * 100))%")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(textSecondary)
            }
            SettingsPanelOpacitySlider(value: value, range: range, step: 0.01)
        }
        .padding(10)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func settingToggleCard(title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(textPrimary)
            Spacer()

            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var shortcutSettingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(ShortcutAction.allCases, id: \.self) { action in
                shortcutRow(for: action)
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func shortcutRow(for action: ShortcutAction) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(action.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(textPrimary)
                Spacer()
                StableText(appState.shortcutDisplayString(for: action), size: 12, weight: .semibold, alpha: 0.94)
                    .frame(width: 92, height: 18)
            }

            Button {
                startShortcutRecording(for: action)
            } label: {
                StableText(
                    recordingShortcutAction == action ? "请按下新快捷键..." : "录制快捷键",
                    size: 12,
                    weight: .semibold,
                    alpha: 0.94
                )
                .frame(maxWidth: .infinity, minHeight: 28)
            }
            .buttonStyle(.plain)
            .focusable(false)
            .background(Color.white.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(10)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func startShortcutRecording(for action: ShortcutAction) {
        stopShortcutRecording()
        recordingShortcutAction = action
        shortcutRecordMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard let recordingAction = recordingShortcutAction else { return event }
            let flags = event.modifierFlags.intersection([.command, .shift, .option, .control])
            // 普通键需要组合修饰键，功能键允许单独录制，例如 F1/F2。
            guard !flags.isEmpty || GlobalShortcutManager.isFunctionKey(event.keyCode) else {
                return nil
            }
            appState.updateShortcut(action: recordingAction, keyCode: event.keyCode, modifierFlagsRaw: flags.rawValue)
            stopShortcutRecording()
            return nil
        }
    }

    private func stopShortcutRecording() {
        recordingShortcutAction = nil
        if let shortcutRecordMonitor {
            NSEvent.removeMonitor(shortcutRecordMonitor)
            self.shortcutRecordMonitor = nil
        }
    }
}

private struct SettingsGlassButtonModifier: ViewModifier {
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
            .shadow(
                color: .black.opacity((isHovering ? 0.24 : 0.14) * intensity),
                radius: isHovering ? 10 : 6,
                x: 0,
                y: isHovering ? 5 : 3
            )
            .animation(.easeOut(duration: 0.16), value: isHovering)
            .onHover { hovering in
                isHovering = hovering
            }
    }
}

private struct SettingsPanelOpacitySlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    private let thumbSize: CGFloat = 16
    private let trackHeight: CGFloat = 5

    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 1)
            let progress = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
                .clamped(to: 0...1)
            let thumbX = progress * (width - thumbSize)

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.20))
                    .frame(height: trackHeight)
                    .padding(.horizontal, thumbSize / 2)

                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.88))
                    .frame(width: thumbX + thumbSize / 2, height: trackHeight)
                    .padding(.leading, thumbSize / 2)

                Circle()
                    .fill(Color.white)
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(color: .black.opacity(0.22), radius: 4, x: 0, y: 2)
                    .offset(x: thumbX)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        // 将拖动位置映射为透明度数值，并按 step 对齐，保证设置保存稳定。
                        let usableWidth = max(width - thumbSize, 1)
                        let rawProgress = ((gesture.location.x - thumbSize / 2) / usableWidth).clamped(to: 0...1)
                        let rawValue = range.lowerBound + Double(rawProgress) * (range.upperBound - range.lowerBound)
                        value = stepped(rawValue)
                    }
            )
        }
        .frame(height: 22)
    }

    private func stepped(_ rawValue: Double) -> Double {
        let steppedValue = (rawValue / step).rounded() * step
        return min(max(steppedValue, range.lowerBound), range.upperBound)
    }
}

private struct SettingsPanelContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
