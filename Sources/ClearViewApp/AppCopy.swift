import Foundation

enum AppCopy {
    // 关键流程：集中维护全局文案，避免分散在各个 View/State 中难以统一修改。
    enum Tab {
        static let eyeRelax = "舒眼"
        static let eyeCare = "护眼"
    }

    enum Footer {
        static let caringLine = "慢慢眨眼，看看远方，给视力一点缓冲。"
    }

    enum ReminderPopup {
        static let preparingTitle = "舒眼时间到，准备好了吗？"
        static let restingTitle = "看看远方，让眼睛放松一下吧"
        static let completedTitle = "真棒！记得坚持下去哦"

        static let preparingMessage = "先停一停，把视线慢慢移开屏幕。"
        static let restingMessage = "慢慢眨眼，给视力一点缓冲。"
        static let completedMessage = "慢慢回来，保持节奏，记得继续舒眼哦"

        static let snoozeHelp = "稍后提醒"
        static let doneHelp = "舒眼完成"
    }

    enum Status {
        static let preparing = "准备放松眼睛"
        static let resting = "看看远方吧"
        static let completed = "真棒，舒眼完成了"
        static let finished = "眼睛放松好了"
    }
}
