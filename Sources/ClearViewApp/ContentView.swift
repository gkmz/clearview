import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @State private var page: Page = .timer
    @State private var showSettings = false
    @State private var showQuitConfirm = false

    private enum Page {
        case timer
        case filter
    }

    // 关键流程：统一色板，避免局部硬编码导致“浅底白字”可读性问题。
    private enum Tone {
        static let bg = Color(red: 0.80, green: 0.88, blue: 0.83)
        static let textPrimary = Color(red: 0.07, green: 0.26, blue: 0.14)
        static let textSecondary = Color(red: 0.18, green: 0.40, blue: 0.24)
        static let selectedFill = Color(red: 0.68, green: 0.84, blue: 0.74)
        static let strongFill = Color(red: 0.30, green: 0.64, blue: 0.36)
    }

    var body: some View {
        ZStack {
            // 关键流程：先给玻璃面板提供可被折射的背景层，否则“玻璃感”会发灰、发闷。
            Tone.bg
                .ignoresSafeArea()

            Circle()
                .fill(Color.white.opacity(0.30))
                .frame(width: 300, height: 300)
                .blur(radius: 40)
                .offset(x: -180, y: -120)

            Circle()
                .fill(Tone.strongFill.opacity(0.20))
                .frame(width: 260, height: 260)
                .blur(radius: 46)
                .offset(x: 190, y: 120)

            glassContainer {
                VStack(spacing: 18) {
                    topTabs

                    if page == .timer {
                        timerPage
                    } else {
                        filterPage
                    }

                    bottomActions
                }
                .padding(20)
            }
            .padding(18)

            if showSettings {
                settingsModal
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .frame(minWidth: 480, minHeight: 380)
        .animation(.easeInOut(duration: 0.18), value: showSettings)
    }

    private var topTabs: some View {
        HStack {
            tabButton(title: "休息", icon: "timer", page: .timer)
            tabButton(title: "过滤", icon: "leaf", page: .filter)
        }
        .padding(6)
        .background(.ultraThinMaterial)
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.55), lineWidth: 1)
        )
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.10), radius: 10, x: 0, y: 5)
    }

    private var timerPage: some View {
        VStack(spacing: 22) {
            Text(format(seconds: appState.secondsUntilBreak))
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Tone.textPrimary)
                .shadow(color: .white.opacity(0.40), radius: 5, x: 0, y: 2)

            HStack(spacing: 16) {
                roundIconButton(
                    systemName: appState.reminderEnabled ? "pause.fill" : "play.fill",
                    accessibility: appState.reminderEnabled ? "暂停" : "开始"
                ) {
                    appState.toggleReminder(!appState.reminderEnabled)
                }

                roundIconButton(systemName: "arrow.clockwise", accessibility: "重置") {
                    appState.resetReminderTimer()
                }
            }
        }
    }

    private var filterPage: some View {
        VStack(spacing: 22) {
            Text(appState.filterLevel.title)
                .font(.system(size: 54, weight: .bold, design: .rounded))
                .foregroundStyle(Tone.textPrimary)
                .shadow(color: .white.opacity(0.40), radius: 5, x: 0, y: 2)

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
                        .frame(width: 66, height: 58)
                        .foregroundStyle(Tone.textPrimary)
                        .background(appState.filterLevel == level ? Tone.selectedFill : Color.clear)
                        .modifier(
                            GlassButtonModifier(
                                cornerRadius: 18,
                                intensity: appState.filterLevel == level ? 0.45 : 1.0
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                    .help("切换到\(level.title)过滤")
                }
            }

            roundIconButton(systemName: "arrow.counterclockwise", accessibility: "恢复默认") {
                appState.applyFilter(.off)
            }
        }
    }

    private var bottomActions: some View {
        HStack(spacing: 14) {
            Spacer()

            if page == .timer {
                bottomIconButton(systemName: "leaf", help: "打开蓝光过滤") {
                    page = .filter
                }
            } else {
                bottomIconButton(systemName: "timer", help: "返回休息计时") {
                    page = .timer
                }
            }

            bottomIconButton(systemName: "gearshape", help: "打开设置") {
                withAnimation(.easeInOut(duration: 0.18)) {
                    showSettings.toggle()
                }
            }

            bottomIconButton(systemName: "bell.badge", help: "测试休息提醒") {
                appState.triggerTestReminderNow()
            }

            bottomIconButton(systemName: "power", help: "退出应用") {
                showQuitConfirm = true
            }
        }
        .alert("退出 ClearView？", isPresented: $showQuitConfirm) {
            Button("取消", role: .cancel) {}
            Button("退出", role: .destructive) {
                appState.quitApplication()
            }
        } message: {
            Text("退出后将停止休息提醒，并恢复默认显示色彩。")
        }
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
                    Text("设置")
                        .font(.headline)
                        .foregroundStyle(Tone.textPrimary)
                    Spacer()
                    Button {
                        showSettings = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(width: 30, height: 30)
                            .foregroundStyle(Tone.textSecondary)
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("关闭设置")
                }

            presetRow(
                title: "提醒间隔",
                values: [20, 25, 45, 60],
                unit: "分钟",
                selected: appState.workIntervalMinutes
            ) { appState.updateInterval($0) }

            presetRow(
                title: "休息时长",
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
            .foregroundStyle(page == target ? Tone.textPrimary : Tone.textSecondary)
            .background(page == target ? Tone.selectedFill.opacity(0.92) : Color.clear)
            .clipShape(Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        // 关键流程：关闭键盘焦点环，避免出现绿色方框边。
        .focusable(false)
        .help("切换到\(title)页面")
    }

    private func roundIconButton(systemName: String, accessibility: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 24, weight: .semibold))
                .frame(width: 58, height: 58)
                .foregroundStyle(Tone.textPrimary)
                .background(Color.clear)
                .modifier(GlassButtonModifier(cornerRadius: 29, intensity: 1.0))
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
                .frame(width: 36, height: 36)
                .foregroundStyle(Tone.textSecondary)
                .background(Color.clear)
                .modifier(GlassButtonModifier(cornerRadius: 18, intensity: 1.0))
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
                    .foregroundStyle(Tone.textSecondary.opacity(0.88))
            }

            HStack(spacing: 8) {
                ForEach(values, id: \.self) { value in
                    Button {
                        onSelect(value)
                    } label: {
                        Text("\(value)")
                            .font(.caption.weight(.semibold))
                            .frame(width: 48, height: 28)
                            .foregroundStyle(Tone.textPrimary)
                            .background(selected == value ? Tone.selectedFill : Color.clear)
                            .modifier(GlassButtonModifier(cornerRadius: 14, intensity: selected == value ? 0.45 : 1.0))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                    .help("设置\(title)为\(value)\(unit)")
                }
            }
        }
    }

    private func glassContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .background(.ultraThinMaterial)
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
            .shadow(color: .black.opacity(0.20), radius: 24, x: 0, y: 14)
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

    func body(content: Content) -> some View {
        content
            // 关键流程：按钮玻璃使用 material + 双描边 + 顶部高光，形成“凸起”质感。
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(0.8 * intensity)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.52 * intensity), lineWidth: 1)
            )
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.16 * intensity))
                    .frame(height: 1)
                    .padding(.horizontal, 6)
            }
            .shadow(color: .black.opacity(0.08 * intensity), radius: 6, x: 0, y: 3)
    }
}
