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
        static let preparingTitle = "舒眼时间到了，慢下来吧"
        static let restingTitle = "看看远方，让眼睛歇一歇"
        static let pomodoroPreparingTitle = "这一轮完成了，先歇一会儿"
        static let pomodoroLongPreparingTitle = "这一组完成了，把时间交给自己"
        static let pomodoroRestingTitle = "休息一会儿，看看远方"
        static let pomodoroLongRestingTitle = "长休息开始了，好好放松吧"
        static let completedTitle = "休息好了，再慢慢回来"

        static let preparingMessage = "先把目光从屏幕上收回来，给眼睛片刻喘息。"
        static let restingMessage = "轻轻眨眨眼，远处的风景正等着你。"
        static let pomodoroPreparingMessage = "这一轮专注辛苦了，先让目光离开屏幕。"
        static let pomodoroLongPreparingMessage = "这一组专注完成了，接下来好好享受这段留白。"
        static let pomodoroRestingMessage = "先望向远处，让眼睛慢慢松开；余下的时光，随心休息。"
        static let pomodoroLongRestingMessage = "先望向远处，等眼睛舒展开来，再把时间留给自己。"
        static let completedMessage = "慢慢回来吧，保持自己的节奏。"
        static let pomodoroCompletedMessage = "休息够了，带着从容回到下一轮专注。"
        static let pomodoroLongCompletedMessage = "这一段长休息结束了，新的专注等你慢慢开始。"

        static let snoozeHelp = "稍后提醒"
        static let doneHelp = "舒眼完成"
        static let pomodoroDoneHelp = "开始下一轮"
    }

}
