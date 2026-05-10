import Foundation

enum AppCopy {
    // 集中维护全局文案，避免分散在各个 View/State 中难以统一修改。
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
        static let pomodoroPreparingTitle = "番茄完成，准备休息一下"
        static let pomodoroRestingTitle = "休息时间，先看看远方"
        static let completedTitle = "真棒！记得坚持下去哦"

        static let preparingMessage = "先停一停，把视线慢慢移开屏幕。"
        static let restingMessage = "慢慢眨眼，给视力一点缓冲。"
        static let pomodoroPreparingMessage = "这一轮专注结束了，先把视线从屏幕移开。"
        static let pomodoroRestingMessage = "前几十秒远眺，后面自由放松。"
        static let completedMessage = "慢慢回来，保持节奏，记得继续舒眼哦"
        static let pomodoroCompletedMessage = "休息结束，准备进入下一轮专注。"

        static let snoozeHelp = "稍后提醒"
        static let doneHelp = "舒眼完成"
        static let pomodoroDoneHelp = "开始下一轮"
    }

    enum Status {
        static let preparing = "准备放松眼睛"
        static let resting = "看看远方吧"
        static let pomodoroPreparing = "准备番茄休息"
        static let pomodoroResting = "番茄休息中"
        static let completed = "真棒，舒眼完成了"
        static let pomodoroCompleted = "休息完成"
        static let finished = "眼睛放松好了"
        static let pomodoroFinished = "开始下一轮专注"
    }
}
