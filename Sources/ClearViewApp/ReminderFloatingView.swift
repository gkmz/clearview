import SwiftUI

struct ReminderFloatingView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }
    private var textPrimary: Color { isDark ? Color.white.opacity(0.92) : Color(red: 0.04, green: 0.20, blue: 0.12) }
    private var textSecondary: Color { isDark ? Color.white.opacity(0.70) : Color(red: 0.27, green: 0.39, blue: 0.32).opacity(0.82) }
    private var panelFill: Color { isDark ? Color.black.opacity(0.62) : Color.white.opacity(0.78) }
    private var panelBorder: Color { isDark ? Color.white.opacity(0.20) : Color(red: 0.72, green: 0.80, blue: 0.74).opacity(0.38) }
    private var buttonFill: Color { isDark ? Color.white.opacity(0.14) : Color.white.opacity(0.62) }
    private var buttonBorder: Color { isDark ? Color.white.opacity(0.20) : Color(red: 0.72, green: 0.80, blue: 0.74).opacity(0.42) }

    var body: some View {
        VStack(spacing: 10) {
            Text(titleText)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(textPrimary)

            Text("\(appState.breakSecondsLeft)")
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(textPrimary)
                .shadow(color: isDark ? Color.black.opacity(0.18) : Color.white.opacity(0.36), radius: 6, x: 0, y: 3)

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
        // 关键流程：提示窗背景使用明确的半透明色，不叠加 material，避免系统毛玻璃让透明度看起来失效。
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(panelFill)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(panelBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.20), radius: 20, x: 0, y: 12)
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
