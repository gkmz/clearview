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

        // 每秒刷新倒计时，并在归零后触发休息提醒再重置。
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
        // 推迟提醒时直接重置剩余秒数，保持主计时器持续运行。
        secondsLeft = max(1, minutes) * 60
        onTick?(secondsLeft)
    }
}
