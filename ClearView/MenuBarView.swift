import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Button("打开 ClearView") {
            // 等待菜单收起后再打开主面板，避免系统菜单窗口吞掉新窗口。
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                appState.showMainPanel()
            }
        }

        Divider()

        Button(appState.reminderEnabled ? "暂不打扰" : "继续提醒") {
            appState.toggleReminder(!appState.reminderEnabled)
        }

        Button("切换到\(appState.rhythmMode == .eyeCare ? "番茄" : "舒眼")") {
            appState.toggleRhythmMode()
        }

        Divider()

        Button("退出 ClearView") {
            appState.quitApplication()
        }
    }
}
