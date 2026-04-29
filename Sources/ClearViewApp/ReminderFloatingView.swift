import SwiftUI

struct ReminderFloatingView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }
    private var textPrimary: Color { Color.white.opacity(0.94) }
    private var textSecondary: Color { Color.white.opacity(0.72) }
    private var opacityFactor: Double { appState.reminderWindowOpacity }
    private var panelFill: Color {
        let opacity = isDark
            ? 0.24 + 0.62 * opacityFactor
            : 0.20 + 0.66 * opacityFactor
        return Color.black.opacity(opacity)
    }
    private var panelBorder: Color { Color.white.opacity((isDark ? 0.20 : 0.24) * opacityFactor) }
    private var buttonFill: Color { Color.white.opacity((isDark ? 0.10 : 0.12) * opacityFactor) }
    private var buttonBorder: Color { Color.white.opacity((isDark ? 0.24 : 0.26) * opacityFactor) }

    var body: some View {
        ZStack {
            panelBackground

            VStack(spacing: 16) {
                titleView

                StableText(
                    "\(appState.breakSecondsLeft)",
                    size: 84,
                    weight: .bold,
                    alpha: 0.94,
                    usesMonospacedDigit: true
                )
                .frame(height: 90)
                .padding(.top, -2)

                HStack(spacing: 22) {
                    if appState.reminderPhase != .completed {
                        floatingIconButton(systemName: "clock.arrow.circlepath") {
                            appState.snoozeBreak(minutes: 5)
                        }
                    }

                    // 关键流程：休息倒计时结束前不允许直接继续，避免用户习惯性忽略提醒。
                    floatingIconButton(systemName: "play.fill", isDisabled: appState.reminderPhase != .completed) {
                        appState.completeBreak()
                    }
                }
                .padding(.top, 4)

                StableText(messageText, size: 17, weight: .medium, alpha: 0.78)
                    .frame(height: 22)
                    .padding(.top, 2)
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 30)
            .id(appState.reminderPhase)
            .transaction { transaction in
                transaction.animation = nil
            }
        }
        .frame(width: 560, height: 300)
        .shadow(color: .black.opacity(isDark ? 0.30 : 0.20), radius: 30, x: 0, y: 18)
        .transaction { transaction in
            transaction.animation = nil
        }
    }

    private var panelBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26)
                .fill(panelFill)

            RoundedRectangle(cornerRadius: 26)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isDark ? 0.08 : 0.18),
                            Color.white.opacity(isDark ? 0.02 : 0.04),
                            Color.black.opacity(isDark ? 0.12 : 0.06)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            RoundedRectangle(cornerRadius: 26)
                .stroke(panelBorder, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var titleView: some View {
        switch appState.reminderPhase {
        case .preparing:
            titleTextView(AppCopy.ReminderPopup.preparingTitle)
        case .completed:
            titleTextView(AppCopy.ReminderPopup.completedTitle)
        default:
            titleTextView(AppCopy.ReminderPopup.restingTitle)
        }
    }

    private func titleTextView(_ text: String) -> some View {
        StableText(text, size: 26, weight: .semibold, alpha: 0.94)
            .frame(height: 34)
    }

    private var messageText: String {
        switch appState.reminderPhase {
        case .preparing:
            return AppCopy.ReminderPopup.preparingMessage
        case .completed:
            return AppCopy.ReminderPopup.completedMessage
        default:
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
                .font(.system(size: 24, weight: .semibold))
                .frame(width: 58, height: 58)
                .foregroundStyle(
                    textPrimary.opacity(
                        isDisabled
                            ? 0.35
                            : (isPrimaryAction ? 0.98 : 0.90)
                    )
                )
                .background(isDark ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Color.clear))
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
        case "play.fill":
            return AppCopy.ReminderPopup.doneHelp
        default:
            return "操作"
        }
    }
}
