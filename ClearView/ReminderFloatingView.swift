import SwiftUI

struct ReminderFloatingView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    /// 当前提醒强度，驱动面板内边距与字号层级。
    private var intensity: ReminderIntensityLevel { appState.reminderIntensity }

    private var isDark: Bool { colorScheme == .dark }
    private var textPrimary: Color { Color.white.opacity(0.94) }
    private var textSecondary: Color { Color.white.opacity(0.72) }
    private var opacityFactor: Double { appState.reminderWindowOpacity }
    private var isFullyOpaque: Bool { opacityFactor >= 0.999 }
    private var panelFill: Color {
        // 关键语义：当滑杆为 100% 时，提示窗主体必须真正不透明，不能再做二次缩放。
        Color.black.opacity(opacityFactor)
    }
    private var panelBorder: Color { Color.white.opacity((isDark ? 0.20 : 0.24) * opacityFactor) }
    private var buttonFill: Color { Color.white.opacity((isDark ? 0.10 : 0.12) * opacityFactor) }
    private var buttonBorder: Color { Color.white.opacity((isDark ? 0.24 : 0.26) * opacityFactor) }

    var body: some View {
        ZStack {
            panelBackground

            VStack(spacing: intensity.vStackSpacing) {
                titleView

                StableText(
                    "\(appState.breakSecondsLeft)",
                    size: intensity.countdownFontSize,
                    weight: .bold,
                    alpha: 0.94,
                    usesMonospacedDigit: true
                )
                .frame(height: intensity.countdownFrameHeight)
                .padding(.top, -2)

                HStack(spacing: intensity.actionHStackSpacing) {
                    if appState.reminderPhase != .completed && !appState.isReminderPreview {
                        floatingIconButton(systemName: "clock.arrow.circlepath") {
                            appState.snoozeBreak(minutes: 5)
                        }
                    }

                    // 休息倒计时结束前不允许直接继续，避免用户习惯性忽略提醒。
                    floatingIconButton(
                        systemName: appState.isReminderPreview ? "xmark" : "play.fill",
                        isDisabled: !appState.isReminderPreview && appState.reminderPhase != .completed
                    ) {
                        appState.completeBreak()
                    }
                }
                .padding(.top, 4)

                StableText(messageText, size: intensity.messageFontSize, weight: .medium, alpha: 0.78)
                    .frame(height: intensity.messageFrameHeight)
                    .padding(.top, 2)
            }
            .padding(.horizontal, intensity.horizontalPadding)
            .padding(.vertical, intensity.verticalPadding)
            .id(appState.reminderPhase)
            .transaction { transaction in
                transaction.animation = nil
            }
        }
        .frame(width: intensity.panelWidth, height: intensity.panelHeight)
        .shadow(color: .black.opacity(isDark ? 0.30 : 0.20), radius: intensity.shadowRadius, x: 0, y: 18)
        .transaction { transaction in
            transaction.animation = nil
        }
    }

    private var panelBackground: some View {
        let r = intensity.cornerRadius
        return ZStack {
            RoundedRectangle(cornerRadius: r, style: .continuous)
                .fill(panelFill)

            RoundedRectangle(cornerRadius: r, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isDark ? 0.06 : 0.12),
                            Color.white.opacity(isDark ? 0.02 : 0.03),
                            Color.black.opacity(isDark ? 0.08 : 0.04)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                // 关键流程：满不透明时关闭玻璃高光叠层，避免肉眼感知到“还有一点透”。
                .opacity(isFullyOpaque ? 0 : 1)

            RoundedRectangle(cornerRadius: r, style: .continuous)
                .stroke(panelBorder, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: r, style: .continuous))
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var titleView: some View {
        switch appState.reminderPhase {
        case .preparing:
            titleTextView(
                appState.activeBreakKind == .pomodoro
                    ? AppCopy.ReminderPopup.pomodoroPreparingTitle
                    : AppCopy.ReminderPopup.preparingTitle
            )
        case .pomodoroResting:
            titleTextView(AppCopy.ReminderPopup.pomodoroRestingTitle)
        case .completed:
            titleTextView(appState.isReminderPreview ? "预览结束" : AppCopy.ReminderPopup.completedTitle)
        default:
            titleTextView(appState.isReminderPreview ? "提醒预览" : AppCopy.ReminderPopup.restingTitle)
        }
    }

    private func titleTextView(_ text: String) -> some View {
        StableText(text, size: intensity.titleFontSize, weight: .semibold, alpha: 0.94)
            .frame(height: intensity.titleFrameHeight)
    }

    private var messageText: String {
        switch appState.reminderPhase {
        case .preparing:
            return appState.activeBreakKind == .pomodoro
                ? AppCopy.ReminderPopup.pomodoroPreparingMessage
                : AppCopy.ReminderPopup.preparingMessage
        case .pomodoroResting:
            return AppCopy.ReminderPopup.pomodoroRestingMessage
        case .completed:
            if appState.isReminderPreview {
                return "预览不会改变当前节奏。"
            }
            return appState.activeBreakKind == .pomodoro
                ? AppCopy.ReminderPopup.pomodoroCompletedMessage
                : AppCopy.ReminderPopup.completedMessage
        default:
            if appState.isReminderPreview {
                return "这是 20 秒提示窗预览，可随时关闭。"
            }
            return AppCopy.ReminderPopup.restingMessage
        }
    }

    private func floatingIconButton(
        systemName: String,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        let isPrimaryAction = systemName == "play.fill"
        return Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: intensity.actionIconPointSize, weight: .semibold))
                .frame(width: intensity.actionButtonSide, height: intensity.actionButtonSide)
                .foregroundStyle(
                    textPrimary.opacity(
                        isDisabled
                            ? 0.35
                            : (isPrimaryAction ? 0.98 : 0.90)
                    )
                )
                // 关键流程：满不透明时移除材质层，防止按钮区域继续采样背后内容。
                .background(
                    isDark && !isFullyOpaque
                        ? AnyShapeStyle(.ultraThinMaterial)
                        : AnyShapeStyle(Color.clear)
                )
                .background(
                    isDisabled
                        ? buttonFill.opacity(0.42)
                        : (isPrimaryAction ? buttonFill.opacity(1.35) : buttonFill)
                )
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .focusable(false)
        .scaleEffect(isDisabled ? 1.0 : (isPrimaryAction ? 1.03 : 1.0))
        .overlay(
            Circle()
                .stroke(
                    isDisabled
                        ? buttonBorder.opacity(0.38)
                        : (isPrimaryAction ? buttonBorder.opacity(1.20) : buttonBorder),
                    lineWidth: isPrimaryAction ? 1.2 : 1
                )
        )
        .shadow(color: .black.opacity(isDisabled ? 0.02 : (isPrimaryAction ? 0.13 : 0.08)), radius: isPrimaryAction ? 9 : 6, x: 0, y: isPrimaryAction ? 4 : 3)
        .hoverTooltip(helpText(for: systemName))
    }

    private func helpText(for systemName: String) -> String {
        switch systemName {
        case "clock.arrow.circlepath":
            return AppCopy.ReminderPopup.snoozeHelp
        case "xmark":
            return "关闭预览"
        case "play.fill":
            return appState.activeBreakKind == .pomodoro
                ? AppCopy.ReminderPopup.pomodoroDoneHelp
                : AppCopy.ReminderPopup.doneHelp
        default:
            return "操作"
        }
    }
}
