import Foundation

/// 用于统一主界面和提醒弹窗的时间语境，避免不同区域出现互相矛盾的关怀文案。
enum TimeContext: Equatable {
    case morning
    case daytime
    case evening
    case lateNight

    /// 根据当前本地时间返回用户所处的时间语境。
    static func current(date: Date = Date(), calendar: Calendar = .current) -> TimeContext {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 5..<11: return .morning
        case 11..<18: return .daytime
        case 18..<23: return .evening
        default: return .lateNight
        }
    }

    /// 返回适合当前时间的主界面问候语。
    var greeting: String {
        switch self {
        case .morning: return "早上好，记得照顾眼睛"
        case .daytime: return "给眼睛一点空隙，也给自己喘口气"
        case .evening: return "晚上好，屏幕可以柔和一点"
        case .lateNight: return "夜深了，早点休息，明天再继续也可以"
        }
    }

    /// 返回适合当前时间的舒眼提醒标题。
    var restingTitle: String {
        switch self {
        case .lateNight: return "已经很晚了，休息一下吧"
        case .evening: return "晚上了，给眼睛一点空隙"
        default: return "看看远方，让眼睛放松一下吧"
        }
    }

    /// 返回适合当前时间的舒眼提醒正文。
    var restingMessage: String {
        switch self {
        case .lateNight: return "今天辛苦了，早点睡，早点休息。"
        case .evening: return "慢慢眨眼，给视力一点缓冲。"
        default: return "慢慢眨眼，给视力一点缓冲。"
        }
    }

    /// 深夜时替换准备阶段的功能性文案，避免继续鼓励用户留在屏幕前。
    var lateNightPreparingTitle: String { "夜深了，今天先休息吧" }

    /// 深夜准备阶段的温暖提示。
    var lateNightPreparingMessage: String { "先放下屏幕，早点睡，明天再继续。" }

    /// 深夜完成阶段的收尾提示。
    var lateNightCompletedTitle: String { "休息好了，早点睡吧" }

    /// 深夜完成阶段不再引导用户进入下一轮工作。
    var lateNightCompletedMessage: String { "今天辛苦了，愿你睡个好觉。" }
}
