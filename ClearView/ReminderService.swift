import Foundation

final class ReminderService {
    var onTick: ((Int) -> Void)?
    var onBreakTriggered: (() -> Void)?

    private var timer: Timer?
    private var secondsLeft: Int = 20 * 60
    private var workInterval: Int = 20

    func start(intervalMinutes: Int) {
        stop()
        workInterval = max(1, intervalMinutes)
        secondsLeft = workInterval * 60
        onTick?(secondsLeft)
        // 关键流程：从零开始一轮工作倒计时，必须挂主线程 Timer。
        scheduleMainTimerIfNeeded()
    }

    func reset(intervalMinutes: Int) {
        // 重置只回到初始倒计时，不自动开始；用户需要再次点击开始。
        stop()
        workInterval = max(1, intervalMinutes)
        secondsLeft = workInterval * 60
        onTick?(secondsLeft)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func forceTrigger() {
        onBreakTriggered?()
        secondsLeft = workInterval * 60
        onTick?(secondsLeft)
    }

    func snooze(minutes: Int) {
        // 推迟提醒时把剩余秒数改为「稍后」间隔；若主 Timer 已被提醒流程 stop，必须重新挂起，否则界面会永远停在这一秒。
        secondsLeft = max(1, minutes) * 60
        onTick?(secondsLeft)
        scheduleMainTimerIfNeeded()
    }

    /// 关键流程：每秒递减 `secondsLeft`，归零时触发休息提醒并重置为整轮工作间隔。
    private func scheduleMainTimerIfNeeded() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.secondsLeft -= 1
            if self.secondsLeft <= 0 {
                self.onBreakTriggered?()
                self.secondsLeft = self.workInterval * 60
            }
            self.onTick?(self.secondsLeft)
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
}
