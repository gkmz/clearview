import SwiftUI

struct ReminderFloatingView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }
    private var textPrimary: Color { Color.white.opacity(0.94) }
    private var textSecondary: Color { Color.white.opacity(0.72) }
    private var panelFill: Color { Color.black.opacity(isDark ? 0.46 : 0.42) }
    private var panelBorder: Color { Color.white.opacity(isDark ? 0.16 : 0.18) }
    private var buttonFill: Color { Color.white.opacity(isDark ? 0.12 : 0.14) }
    private var buttonBorder: Color { Color.white.opacity(isDark ? 0.18 : 0.20) }

    var body: some View {
        VStack(spacing: 10) {
            Text(titleText)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(textPrimary)

            Text("\(appState.breakSecondsLeft)")
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(textPrimary)
                .shadow(color: isDark ? Color.black.opacity(0.24) : Color.white.opacity(0.30), radius: 6, x: 0, y: 3)

            HStack(spacing: 16) {
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

            Text(messageText)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(textSecondary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .frame(width: 420, height: 210)
        // 关键流程：浅色使用浅灰透明卡片，深色提高透明度，保持高级感和可读性。
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(panelFill)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(panelBorder, lineWidth: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isDark ? 0.05 : 0.16),
                            Color.clear,
                            Color.black.opacity(isDark ? 0.10 : 0.04)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .allowsHitTesting(false)
        )
        .shadow(color: .black.opacity(isDark ? 0.28 : 0.18), radius: 24, x: 0, y: 14)
    }

    private var titleText: String {
        switch appState.reminderPhase {
        case .preparing:
            return "休息时间到了，准备好了吗？"
        case .completed:
            return "很好，记得坚持下去"
        default:
            return "看看远方，让眼睛放松一下"
        }
    }

    private var messageText: String {
        switch appState.reminderPhase {
        case .preparing:
            return "先停一停，把视线慢慢移开屏幕。"
        case .completed:
            return "慢慢回来，保持节奏。"
        default:
            return "慢慢眨眼，给视力一点缓冲。"
        }
    }

    private func floatingIconButton(
        systemName: String,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 40, height: 40)
                .foregroundStyle(textPrimary.opacity(isDisabled ? 0.35 : 0.92))
                .background(isDark ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Color.clear))
                .background(isDisabled ? buttonFill.opacity(0.42) : buttonFill)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .focusable(false)
        .overlay(
            Circle()
                .stroke(isDisabled ? buttonBorder.opacity(0.38) : buttonBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(isDisabled ? 0.02 : 0.08), radius: 6, x: 0, y: 3)
        .help(helpText(for: systemName))
    }

    private func helpText(for systemName: String) -> String {
        switch systemName {
        case "clock.arrow.circlepath":
            return "稍后提醒"
        case "play.fill":
            return "休息好了"
        default:
            return "操作"
        }
    }
}
