import SwiftUI

struct ReminderFloatingView: View {
    @EnvironmentObject private var appState: AppState
// d
    var body: some View {
        VStack(spacing: 10) {
            Text(appState.breakSecondsLeft == 0 ? "很好，眼睛已经得到了放松" : "让眼睛看向远方，放松一下吧")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.92))

            Text("\(appState.breakSecondsLeft)")
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color.white.opacity(0.96))
                .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 3)

            HStack(spacing: 16) {
                floatingIconButton(systemName: "clock.arrow.circlepath") {
                    appState.snoozeBreak(minutes: 5)
                }

                floatingIconButton(systemName: "play.fill") {
                    appState.completeBreak()
                }
            }

            Text(appState.breakSecondsLeft == 0 ? "可以回到工作中来了，记得保持节奏哦。" : "休息一下，眺望远方，给眼睛一点缓冲吧")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.70))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .frame(width: 420, height: 210)
        .background(.ultraThinMaterial)
        .background(Color.black.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.20), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.20), radius: 20, x: 0, y: 12)
    }

    private func floatingIconButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 40, height: 40)
                .foregroundStyle(Color.white.opacity(0.92))
                .background(.ultraThinMaterial)
                .background(Color.white.opacity(0.14))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .focusable(false)
        .overlay(
            Circle()
                .stroke(Color.white.opacity(0.20), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
        .help(helpText(for: systemName))
    }

    private func helpText(for systemName: String) -> String {
        switch systemName {
        case "clock.arrow.circlepath":
            return "推迟5分钟"
        case "play.fill":
            return "继续并重新计时"
        default:
            return "操作"
        }
    }
}
