import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Button("打开 ClearView") {
            // 关键流程：等待菜单收起后再打开主面板，避免系统菜单窗口吞掉新窗口。
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                appState.showMainPanel()
            }
        }

        Divider()

        Button(appState.reminderEnabled ? "暂不打扰" : "继续提醒") {
            appState.toggleReminder(!appState.reminderEnabled)
        }

        Divider()

        Button("退出 ClearView") {
            appState.quitApplication()
        }
    }
}
