import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var page: Page = .timer
    @State private var showSettings = false

    private enum Page {
        case timer
        case filter
    }

    // 关键流程：统一四个区域的尺寸比例，避免页面切换时布局抖动。
    private enum Layout {
        static let cardPadding: CGFloat = 18
        static let sectionSpacing: CGFloat = 10
        static let topTabHeight: CGFloat = 56
        static let displayHeight: CGFloat = 104
        static let functionHeight: CGFloat = 72
        static let systemHeight: CGFloat = 46
    }

    // 关键流程：根据系统深浅色自动切换背景、文字、按钮层级。
    private var isDark: Bool { colorScheme == .dark }
    private var textPrimary: Color { isDark ? Color.white.opacity(0.97) : Color(red: 0.06, green: 0.24, blue: 0.14) }
    private var textSecondary: Color { isDark ? Color.white.opacity(0.86) : Color(red: 0.14, green: 0.34, blue: 0.22) }
    private var selectedFill: Color { isDark ? Color.white.opacity(0.24) : Color.white.opacity(0.58) }
    private var panelTint: Color { isDark ? Color.white.opacity(0.08) : Color.white.opacity(0.34) }
    private var buttonTint: Color { isDark ? Color.white.opacity(0.22) : Color.white.opacity(0.48) }
    private var buttonBorder: Color { isDark ? Color.white.opacity(0.22) : Color.white.opacity(0.44) }
    private var textShadow: Color { isDark ? Color.black.opacity(0.50) : Color.white.opacity(0.42) }

    var body: some View {
        ZStack {
            // 关键流程：菜单窗口外壳不可控，根视图不再额外做圆角外框，避免多重边框。
            (isDark ? Color.black.opacity(0.35) : Color(red: 0.80, green: 0.88, blue: 0.83).opacity(0.38))

            Circle()
                .fill((isDark ? Color.white.opacity(0.03) : Color.white.opacity(0.12)))
                .frame(width: 280, height: 280)
                .blur(radius: 46)
                .offset(x: -170, y: -88)

            Circle()
                .fill((isDark ? Color.white.opacity(0.02) : Color(red: 0.50, green: 0.72, blue: 0.60).opacity(0.10)))
                .frame(width: 240, height: 240)
                .blur(radius: 54)
                .offset(x: 180, y: 116)

            VStack(spacing: Layout.sectionSpacing) {
                topTabs
                    .frame(height: Layout.topTabHeight)

                pageDisplayArea
                    .frame(maxWidth: .infinity, minHeight: Layout.displayHeight, maxHeight: Layout.displayHeight)

                pageFunctionArea
                    .frame(maxWidth: .infinity, minHeight: Layout.functionHeight, maxHeight: Layout.functionHeight)

                bottomActions
                    .frame(maxWidth: .infinity, minHeight: Layout.systemHeight, maxHeight: Layout.systemHeight)
            }
            .padding(Layout.cardPadding)

            if showSettings {
                settingsModal
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .frame(minWidth: 480, minHeight: 350)
        .animation(.easeInOut(duration: 0.18), value: showSettings)
    }

    private var topTabs: some View {
        HStack {
            tabButton(title: "休息", icon: "timer", page: .timer)
            tabButton(title: "护眼", icon: "leaf", page: .filter)
        }
        .padding(6)
        .background(.ultraThinMaterial)
        .background(isDark ? Color.white.opacity(0.05) : panelTint)
        .overlay(
            Capsule()
                .stroke(isDark ? Color.white.opacity(0.13) : Color.white.opacity(0.45), lineWidth: 1)
        )
        .clipShape(Capsule())
        .shadow(color: .black.opacity(isDark ? 0.34 : 0.10), radius: 14, x: 0, y: 7)
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
                Text(format(seconds: appState.secondsUntilBreak))
                    .font(.system(size: 78, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(textPrimary)
                    .shadow(color: textShadow, radius: 10, x: 0, y: 4)
            } else {
                Text("护眼模式")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(textPrimary)
                    .shadow(color: textShadow, radius: 8, x: 0, y: 3)
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
                        .help("选择\(level.title)")
                    }
                }
            }
        }
    }

    private var bottomActions: some View {
        HStack(spacing: 12) {
            Spacer()

            if page == .timer {
                // 关键流程：休息页底部只保留设置、测试、退出。
                bottomIconButton(systemName: "gearshape", help: "调整节奏") {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        showSettings.toggle()
                    }
                }

                bottomIconButton(systemName: "bell.badge", help: "试试提醒") {
                    appState.triggerTestReminderNow()
                }
            } else {
                // 关键流程：过滤页底部仅保留退出按钮，减少重复操作入口。
            }

            bottomIconButton(systemName: "power", help: "退出 ClearView") {
                // 关键流程：MenuBarExtra 场景下 alert 容易与菜单行为冲突，改为点击即退出。
                appState.quitApplication()
            }
        }
        .padding(.horizontal, 2)
    }

    private var settingsModal: some View {
        ZStack {
            Color.black.opacity(0.12)
                .ignoresSafeArea()
                .onTapGesture {
                    showSettings = false
                }

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
                    .help("收起设置")
                }

            presetRow(
                title: "多久提醒",
                values: [20, 25, 45, 60],
                unit: "分钟",
                selected: appState.workIntervalMinutes
            ) { appState.updateInterval($0) }

            presetRow(
                title: "休息多久",
                values: [20, 40, 60, 90],
                unit: "秒",
                selected: appState.breakDurationSeconds
            ) { appState.updateBreakDuration($0) }
            }
            .padding(18)
            .frame(width: 340)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.55), lineWidth: 1)
            )
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.16))
                    .frame(height: 1)
                    .padding(.horizontal, 14)
            }
            .shadow(color: .black.opacity(0.18), radius: 24, x: 0, y: 14)
        }
    }

    private func tabButton(title: String, icon: String, page target: Page) -> some View {
        Button {
            page = target
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            // 关键流程：将每个分段按钮扩展为整段可点击，避免“只能点文字”。
            .frame(maxWidth: .infinity)
            .font(.system(size: 13, weight: .semibold))
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .foregroundStyle(page == target ? textPrimary : textSecondary)
            .background(page == target ? (isDark ? Color.white.opacity(0.18) : selectedFill) : Color.clear)
            .modifier(HoverActivationModifier(cornerRadius: 999, tint: selectedFill, isActive: page == target))
            .clipShape(Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        // 关键流程：关闭键盘焦点环，避免出现绿色方框边。
        .focusable(false)
        .help("看看\(title)")
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
        .help(accessibility)
    }

    private func bottomIconButton(systemName: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 40, height: 40)
                .foregroundStyle(textSecondary)
                .background(Color.clear)
                .modifier(GlassButtonModifier(cornerRadius: 20, intensity: 1.0, tint: buttonTint, border: buttonBorder))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .focusable(false)
        .help(help)
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
                Spacer()
                Text("\(selected)\(unit)")
                    .font(.caption)
                    .foregroundStyle(textSecondary.opacity(0.92))
            }

            HStack(spacing: 8) {
                ForEach(values, id: \.self) { value in
                    Button {
                        onSelect(value)
                    } label: {
                        Text("\(value)")
                            .font(.caption.weight(.semibold))
                            .frame(width: 48, height: 28)
                            .foregroundStyle(textPrimary)
                            .background(selected == value ? selectedFill : Color.clear)
                            .modifier(GlassButtonModifier(cornerRadius: 14, intensity: selected == value ? 0.45 : 1.0, tint: buttonTint, border: buttonBorder))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                    .help("\(value)\(unit)")
                }
            }
        }
    }

    private func glassContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .background(.ultraThinMaterial)
            .background(panelTint)
            .clipShape(RoundedRectangle(cornerRadius: 32))
            .overlay(
                RoundedRectangle(cornerRadius: 32)
                    .stroke(Color.white.opacity(0.55), lineWidth: 1)
            )
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color.white.opacity(0.18))
                    .frame(height: 1)
                    .padding(.horizontal, 18)
                    .padding(.top, 10)
            }
            .overlay(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color.black.opacity(0.08))
                    .frame(height: 28)
                    .blur(radius: 20)
                    .offset(y: 10)
            }
            .shadow(color: .black.opacity(isDark ? 0.46 : 0.18), radius: 24, x: 0, y: 14)
    }

    private func format(seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

private struct GlassButtonModifier: ViewModifier {
    let cornerRadius: CGFloat
    let intensity: CGFloat
    let tint: Color
    let border: Color
    @State private var isHovering = false

    func body(content: Content) -> some View {
        let fillOpacity = (isHovering ? 0.28 : 0.18) * intensity
        let borderOpacity = (isHovering ? 0.36 : 0.24) * intensity

        content
            // 关键流程：保留通透感，去掉复杂边缘效果，只用轻背景、细边框和 hover 提亮表达状态。
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(tint.opacity(fillOpacity))
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
