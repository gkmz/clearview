import SwiftUI

struct ReminderFloatingView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 14) {
            Text(appState.breakSecondsLeft == 0 ? "休息完成" : "请休息")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.90))

            Text("\(appState.breakSecondsLeft)")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color.white.opacity(0.96))
                .shadow(color: .black.opacity(0.16), radius: 6, x: 0, y: 3)

            HStack(spacing: 14) {
                floatingIconButton(systemName: "xmark") {
                    appState.skipBreak()
                }

                floatingIconButton(systemName: "clock.arrow.circlepath") {
                    appState.snoozeBreak(minutes: 5)
                }

                floatingIconButton(systemName: "play.fill") {
                    appState.completeBreak()
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .background(.ultraThinMaterial)
        .background(Color.white.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.white.opacity(0.55), lineWidth: 1)
        )
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.white.opacity(0.16))
                .frame(height: 1)
                .padding(.horizontal, 16)
                .padding(.top, 8)
        }
        .shadow(color: .black.opacity(0.20), radius: 20, x: 0, y: 12)
    }

    private func floatingIconButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 44, height: 44)
                .foregroundStyle(Color.white.opacity(0.92))
                .background(.ultraThinMaterial)
                .background(Color(red: 0.78, green: 0.67, blue: 0.78).opacity(0.36))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .focusable(false)
        .overlay(
            Circle()
                .stroke(Color.white.opacity(0.52), lineWidth: 1)
        )
        .overlay(alignment: .top) {
            Circle()
                .fill(Color.white.opacity(0.14))
                .frame(width: 38, height: 12)
                .offset(y: -10)
        }
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
        .help(helpText(for: systemName))
    }

    private func helpText(for systemName: String) -> String {
        switch systemName {
        case "xmark":
            return "跳过本次休息"
        case "clock.arrow.circlepath":
            return "推迟5分钟"
        case "play.fill":
            return "继续并重新计时"
        default:
            return "操作"
        }
    }
}
