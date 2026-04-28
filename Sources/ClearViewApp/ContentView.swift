import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var page: Page = .timer
    @State private var showSettings = false
    @State private var now = Date()
    @State private var isRecordingShortcut = false
    @State private var shortcutRecordMonitor: Any?
    @State private var isRhythmSettingsExpanded = true
    @State private var isAppearanceSettingsExpanded = false
    @State private var isPreferenceSettingsExpanded = false
    @State private var settingsContentHeight: CGFloat = 0

    private enum Page {
        case timer
        case filter
    }

    // 关键流程：统一四个区域的尺寸比例，避免页面切换时布局抖动。
    private enum Layout {
        static let timerCardWidth: CGFloat = 480
        static let timerCardHeight: CGFloat = 236
        static let cardPadding: CGFloat = 22
        static let sectionSpacing: CGFloat = 10
        static let topTabHeight: CGFloat = 48
        static let displayHeight: CGFloat = 86
        static let functionHeight: CGFloat = 58
    }

    // 关键流程：背景图片仍按系统深浅色切换，但 UI 基底统一为黑色玻璃风格。
    private var isDark: Bool { colorScheme == .dark }
    private var mainOpacity: Double { appState.mainWindowOpacity }
    private var settingsBackdropOpacity: Double {
        appState.useBackgroundImage ? 0.76 * mainOpacity : 0.76
    }
    private var textPrimary: Color { Color.white.opacity(0.96) }
    private var textSecondary: Color { Color.white.opacity(0.78) }
    private var selectedFill: Color { Color.white.opacity(0.24) }
    private var buttonTint: Color { Color.white.opacity(0.20) }
    private var buttonBorder: Color { Color.white.opacity(0.22) }

    var body: some View {
        ZStack {
            immersiveBackground

            // 关键流程：沉浸式主界面只保留少量信息，降低工具感，后续可替换为真实背景图。
            VStack(spacing: 16) {
                clockHeader
                    .padding(.top, 34)

                Spacer(minLength: 6)

                timerCard

                quoteFooter
                    .padding(.top, 4)

                // 关键流程：底部系统按钮移到主界面右下角后，给提示文案预留更大下边距，视觉上相当于“上移”。
                Spacer(minLength: 72)
            }
            .padding(.horizontal, 40)

            // 关键流程：将设置/测试/隐藏按钮移到主界面右下角，不再占用中间内容卡片高度。
            globalBottomActions
                .padding(.trailing, 34)
                .padding(.bottom, 28)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)

            if showSettings {
                settingsModal
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .frame(minWidth: 920, minHeight: 540)
        .animation(.easeInOut(duration: 0.18), value: showSettings)
        .onReceive(Timer.publish(every: 30, on: .main, in: .common).autoconnect()) { value in
            now = value
        }
    }

    private var immersiveBackground: some View {
        GeometryReader { proxy in
            ZStack {
                backgroundImage
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()

                // 关键流程：背景图只是氛围层，遮罩负责保证白色文字始终清晰。
                Color.black.opacity(0.42 * mainOpacity)

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.26 * mainOpacity),
                        Color.black.opacity(0.06 * mainOpacity),
                        Color.black.opacity(0.34 * mainOpacity)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private var backgroundImage: some View {
        // 关键流程：允许用户关闭背景图，直接回退为纯色背景，减少干扰。
        if appState.useBackgroundImage {
            // 关键流程：SwiftPM 资源中的图片用 Bundle.module 显式读取，避免名称解析失败。
            if let url = Bundle.module.url(forResource: isDark ? "dark" : "light", withExtension: "jpg"),
               let image = NSImage(contentsOf: url) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .opacity(appState.backgroundImageOpacity)
            } else {
                Color.black
                    .opacity(mainOpacity)
            }
        } else {
            Color.black
                .opacity(mainOpacity)
        }
    }

    private var clockHeader: some View {
        VStack(spacing: 8) {
            StableText(formatTime(now), size: 56, weight: .light, alpha: 0.96, usesMonospacedDigit: true)
                .frame(height: 64)

            StableText(formatDate(now), size: 13, weight: .medium, alpha: 0.78)
                .frame(height: 18)

            StableText(greetingText, size: 18, weight: .semibold, alpha: 0.96)
                .frame(height: 24)
                .padding(.top, 6)
        }
    }

    private var timerCard: some View {
        VStack(spacing: Layout.sectionSpacing) {
            topTabs
                .frame(height: Layout.topTabHeight)

            pageDisplayArea
                .frame(maxWidth: .infinity, minHeight: Layout.displayHeight, maxHeight: Layout.displayHeight)

            pageFunctionArea
                .frame(maxWidth: .infinity, minHeight: Layout.functionHeight, maxHeight: Layout.functionHeight)
        }
        .padding(Layout.cardPadding)
        .frame(width: Layout.timerCardWidth, height: Layout.timerCardHeight)
        // 关键流程：去掉功能区独立灰底，让功能区和标题区共享主界面同一层背景。
    }

    private var quoteFooter: some View {
        VStack(spacing: 6) {
            StableText(AppCopy.Footer.caringLine, size: 14, weight: .medium, alpha: 0.88)
                .frame(height: 20)
        }
    }

    private var topTabs: some View {
        HStack {
            tabButton(title: AppCopy.Tab.eyeRelax, page: .timer)
            tabButton(title: AppCopy.Tab.eyeCare, page: .filter)
        }
        .padding(6)
        // 关键流程：透明面板内的系统毛玻璃会变白，这里改用低透明手工叠层，保证背景图直接透出。
        .background {
            ZStack {
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.08))
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.22),
                                Color.white.opacity(0.07),
                                Color.black.opacity(0.06)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .clipShape(Capsule(style: .continuous))
        }
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(0.42), lineWidth: 1)
        )
        .overlay(alignment: .top) {
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.32))
                .frame(height: 1)
                .padding(.horizontal, 20)
        }
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.22), radius: 14, x: 0, y: 7)
    }
    private var timerPage: some View {
        EmptyView()
    }

    private var filterPage: some View {
        EmptyView()
    }

    // 关键流程：中部显示区只承载“大信息”，保证两页尺寸一致。
    private var pageDisplayArea: some View {
        Group {
            if page == .timer {
                StableText(
                    format(seconds: appState.secondsUntilBreak),
                    size: 72,
                    weight: .bold,
                    alpha: 0.96,
                    usesMonospacedDigit: true
                )
                .frame(height: 82)
            } else {
                StableText("护眼模式", size: 42, weight: .bold, alpha: 0.96)
                    .frame(height: 52)
            }
        }
    }

    // 关键流程：功能按钮区承载页面内操作，和系统按钮区分层。
    private var pageFunctionArea: some View {
        Group {
            if page == .timer {
                HStack(spacing: 14) {
                    roundIconButton(
                        systemName: appState.reminderEnabled ? "pause.fill" : "play.fill",
                        accessibility: appState.reminderEnabled ? "暂停计时" : "开始计时"
                    ) {
                        appState.toggleReminder(!appState.reminderEnabled)
                    }

                    roundIconButton(systemName: "arrow.clockwise", accessibility: "重新开始") {
                        appState.resetReminderTimer()
                    }
                }
            } else {
                HStack(spacing: 10) {
                    ForEach(BlueLightLevel.allCases, id: \.self) { level in
                        Button {
                            appState.applyFilter(level)
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: level.iconName)
                                    .font(.system(size: 18, weight: .semibold))
                                Text(level.title)
                                    .font(.caption)
                            }
                            .frame(width: 64, height: 56)
                            .foregroundStyle(textSecondary)
                            .background(appState.filterLevel == level ? selectedFill : Color.clear)
                            .modifier(
                                GlassButtonModifier(
                                    cornerRadius: 18,
                                    intensity: appState.filterLevel == level ? 0.45 : 1.0,
                                    tint: buttonTint,
                                    border: buttonBorder
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                        .buttonStyle(.plain)
                        .hoverTooltip("选择\(level.title)")
                    }
                }
            }
        }
    }

    private var globalBottomActions: some View {
        HStack(spacing: 12) {
            // 关键流程：设置入口全局可用，快捷键配置不依赖当前页签。
            bottomIconButton(
                systemName: "gearshape",
                help: "调整节奏"
            ) {
                withAnimation(.easeInOut(duration: 0.18)) {
                    showSettings.toggle()
                }
            }

            bottomIconButton(
                systemName: "bell.badge",
                help: page == .timer ? "试试提醒" : "护眼页暂不可用",
                isDisabled: page != .timer
            ) {
                appState.triggerTestReminderNow()
            }

            bottomIconButton(systemName: "power", help: "隐藏主界面") {
                appState.hideMainPanel()
            }
        }
        .padding(.horizontal, 2)
    }

    private var settingsModal: some View {
        ZStack {
            Color.black.opacity(settingsBackdropOpacity)
                .ignoresSafeArea()
                .onTapGesture {
                    showSettings = false
                }

            GeometryReader { proxy in
                // 关键流程：设置窗随内容增减自然伸缩，但整体高度不能超过主界面上下留白后的可用高度。
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
                        showSettings = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(width: 30, height: 30)
                            .foregroundStyle(textSecondary)
                            .background(Color.clear)
                            .modifier(GlassButtonModifier(cornerRadius: 15, intensity: 1.0, tint: buttonTint, border: buttonBorder))
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
                // 关键流程：内容未超高时按自然高度收缩；超高时由 maxHeight 截断并启用滚动。
                .fixedSize(horizontal: false, vertical: true)
                .onPreferenceChange(SettingsContentHeightKey.self) { height in
                    settingsContentHeight = height
                }
            }
            .padding(18)
            .frame(width: 340)
            .frame(maxHeight: maxModalHeight)
            .fixedSize(horizontal: false, vertical: true)
            .background(Color.black.opacity(0.62))
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
            .onAppear {
                // 关键流程：设置弹窗打开时临时禁用窗口背景拖动，避免拖动滑杆时拖走整个主界面。
                appState.setMainPanelMovableByBackground(false)
            }
            .onDisappear {
                stopShortcutRecording()
                appState.setMainPanelMovableByBackground(true)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
    }

    private var settingsSectionsContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            settingsSection(title: "节奏", isExpanded: $isRhythmSettingsExpanded) {
                presetRow(
                    title: "多久提醒",
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

                opacitySettingRow(
                    title: "提示窗透明度",
                    value: Binding(
                        get: { appState.reminderWindowOpacity },
                        set: { appState.updateReminderWindowOpacity($0) }
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
                    .preference(key: SettingsContentHeightKey.self, value: proxy.size.height)
            }
        )
    }

    private func bottomIconButton(
        systemName: String,
        help: String,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 40, height: 40)
                .foregroundStyle(textSecondary.opacity(isDisabled ? 0.50 : 1.0))
                .background(Color.clear)
                .modifier(GlassButtonModifier(cornerRadius: 20, intensity: isDisabled ? 0.55 : 1.0, tint: buttonTint, border: buttonBorder))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .focusable(false)
        .disabled(isDisabled)
        .hoverTooltip(help)
    }

    private func settingsSection<Content: View>(
        title: String,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: isExpanded.wrappedValue ? 10 : 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    isExpanded.wrappedValue.toggle()
                }
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
            WhiteOpacitySlider(value: value, range: range, step: 0.01)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("打开主界面快捷键")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(textPrimary)
                Spacer()
                StableText(appState.shortcutDisplayString, size: 12, weight: .semibold, alpha: 0.94)
                    .frame(width: 84, height: 18)
            }

            Button {
                startShortcutRecording()
            } label: {
                StableText(
                    isRecordingShortcut ? "请按下新快捷键..." : "录制快捷键",
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
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func startShortcutRecording() {
        stopShortcutRecording()
        isRecordingShortcut = true
        shortcutRecordMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard isRecordingShortcut else { return event }
            let flags = event.modifierFlags.intersection([.command, .shift, .option, .control])
            // 关键流程：普通键需要组合修饰键，功能键允许单独录制，例如 F1/F2。
            guard !flags.isEmpty || GlobalShortcutManager.isFunctionKey(event.keyCode) else {
                return nil
            }
            appState.updateShortcut(keyCode: event.keyCode, modifierFlagsRaw: flags.rawValue)
            stopShortcutRecording()
            return nil
        }
    }

    private func stopShortcutRecording() {
        isRecordingShortcut = false
        if let shortcutRecordMonitor {
            NSEvent.removeMonitor(shortcutRecordMonitor)
            self.shortcutRecordMonitor = nil
        }
    }

    private func tabButton(title: String, page target: Page) -> some View {
        Button {
            page = target
        } label: {
            Text(title)
            // 关键流程：将每个分段按钮扩展为整段可点击，避免“只能点文字”。
            .frame(maxWidth: .infinity)
            .font(.system(size: 15, weight: .semibold))
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .foregroundStyle(page == target ? textPrimary : textSecondary)
            .background {
                if page == target {
                    ZStack {
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.12))
                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.26),
                                        Color.white.opacity(0.07)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    .clipShape(Capsule(style: .continuous))
                }
            }
            .overlay(
                Capsule()
                    .stroke(
                        page == target
                            ? Color.white.opacity(0.42)
                            : Color.clear,
                        lineWidth: 1
                    )
            )
            .modifier(HoverActivationModifier(cornerRadius: 999, tint: selectedFill, isActive: page == target))
            .clipShape(Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        // 关键流程：关闭键盘焦点环，避免出现绿色方框边。
        .focusable(false)
        .hoverTooltip("看看\(title)")
    }

    private func roundIconButton(systemName: String, accessibility: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 24, weight: .semibold))
                .frame(width: 58, height: 58)
                .foregroundStyle(textPrimary)
                .background(Color.clear)
                .modifier(GlassButtonModifier(cornerRadius: 29, intensity: 1.0, tint: buttonTint, border: buttonBorder))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .focusable(false)
        .accessibilityLabel(accessibility)
        .hoverTooltip(accessibility)
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
                                GlassButtonModifier(
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

    private func format(seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter.string(from: date)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: now)
        switch hour {
        case 5..<11:
            return "早上好，记得照顾眼睛"
        case 11..<14:
            return "中午好，给眼睛一点空隙"
        case 14..<18:
            return "下午好，别忘了看远方"
        case 18..<23:
            return "晚上好，屏幕可以柔和一点"
        default:
            return "夜深了，让眼睛慢慢休息"
        }
    }
}

private struct GlassButtonModifier: ViewModifier {
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
            // 关键流程：按钮统一使用手工半透明玻璃层，避免系统 material 在浅色背景下变成实灰块。
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

private struct WhiteOpacitySlider: View {
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
                        // 关键流程：将拖动位置映射为透明度数值，并按 step 对齐，保证设置保存稳定。
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

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

private struct SettingsContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct HoverActivationModifier: ViewModifier {
    let cornerRadius: CGFloat
    let tint: Color
    let isActive: Bool
    @State private var isHovering = false

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(tint.opacity(!isActive && isHovering ? 0.18 : 0.0))
            )
            .scaleEffect(isHovering ? 1.015 : 1.0)
            .animation(.easeOut(duration: 0.16), value: isHovering)
            .onHover { hovering in
                isHovering = hovering
            }
    }
}
