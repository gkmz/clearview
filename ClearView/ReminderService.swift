import Foundation

struct RhythmConfiguration: Equatable {
    var mode: RhythmMode
    var eyeIntervalMinutes: Int
    var eyeBreakDurationSeconds: Int
    var pomodoroFocusMinutes: Int
    var pomodoroBreakMinutes: Int
    var pomodoroRoundsPerSet: Int = 4
    var pomodoroLongBreakMinutes: Int = 15
    // Legacy settings kept for decoding older preferences. Pomodoro focus no longer
    // inserts eye-care breaks; rest starts after the focus session ends.
    var pomodoroEyeBreakEnabled: Bool
    var mergeEyeBreakThresholdSeconds: Int

    var initialFocusSeconds: Int {
        switch mode {
        case .eyeCare:
            return max(1, eyeIntervalMinutes) * 60
        case .pomodoro:
            return max(1, pomodoroFocusMinutes) * 60
        }
    }

    var eyeIntervalSeconds: Int {
        max(1, eyeIntervalMinutes) * 60
    }

    var eyeBreakSeconds: Int {
        max(5, eyeBreakDurationSeconds)
    }

    var pomodoroBreakSeconds: Int {
        max(1, pomodoroBreakMinutes) * 60
    }

    var pomodoroLongBreakSeconds: Int {
        max(1, pomodoroLongBreakMinutes) * 60
    }
}

enum RhythmBreakKind: Equatable {
    case eye
    case pomodoro
    case pomodoroLong
}

enum RhythmServicePhase: Equatable {
    case focus
    case breakTime(RhythmBreakKind)
}

struct RhythmTick: Equatable {
    var phase: RhythmServicePhase
    var secondsLeft: Int
    var focusSecondsRemaining: Int
    var completedPomodoroRounds: Int
}

final class ReminderService {
    var onTick: ((RhythmTick) -> Void)?
    var onBreakTriggered: ((RhythmBreakKind) -> Void)?

    private var timer: Timer?
    private var configuration = RhythmConfiguration(
        mode: .eyeCare,
        eyeIntervalMinutes: 20,
        eyeBreakDurationSeconds: 20,
        pomodoroFocusMinutes: 25,
        pomodoroBreakMinutes: 5,
        pomodoroRoundsPerSet: 4,
        pomodoroLongBreakMinutes: 15,
        pomodoroEyeBreakEnabled: true,
        mergeEyeBreakThresholdSeconds: 120
    )
    private var phase: RhythmServicePhase = .focus
    private var focusSecondsRemaining: Int = 20 * 60
    private var phaseSecondsLeft: Int = 20 * 60
    /// 当前番茄组已完成的专注轮次，长休息完成后归零。
    private(set) var completedPomodoroRounds = 0

    func start(configuration: RhythmConfiguration) {
        stop()
        self.configuration = normalized(configuration)
        completedPomodoroRounds = 0
        beginFocus()
        scheduleMainTimerIfNeeded()
    }

    func reset(configuration: RhythmConfiguration) {
        stop()
        self.configuration = normalized(configuration)
        completedPomodoroRounds = 0
        beginFocus()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func resume(configuration: RhythmConfiguration) {
        self.configuration = normalized(configuration)
        emitTick()
        scheduleMainTimerIfNeeded()
    }

    func forceTrigger(kind: RhythmBreakKind = .eye) {
        stop()
        beginBreak(kind)
        onBreakTriggered?(kind)
    }

    func completeBreak() {
        if case .breakTime(.pomodoroLong) = phase {
            completedPomodoroRounds = 0
        }
        beginFocus()
        scheduleMainTimerIfNeeded()
    }

    func skipBreak() {
        if case .breakTime(.pomodoroLong) = phase {
            completedPomodoroRounds = 0
        }
        beginFocus()
        scheduleMainTimerIfNeeded()
    }

    func snooze(minutes: Int) {
        stop()
        phase = .focus
        focusSecondsRemaining = max(1, minutes) * 60
        phaseSecondsLeft = focusSecondsRemaining
        emitTick()
        scheduleMainTimerIfNeeded()
    }

    func advanceOneSecondForTesting() {
        advanceOneSecond()
    }

    private func normalized(_ configuration: RhythmConfiguration) -> RhythmConfiguration {
        RhythmConfiguration(
            mode: configuration.mode,
            eyeIntervalMinutes: max(1, configuration.eyeIntervalMinutes),
            eyeBreakDurationSeconds: max(5, configuration.eyeBreakDurationSeconds),
            pomodoroFocusMinutes: max(1, configuration.pomodoroFocusMinutes),
            pomodoroBreakMinutes: max(1, configuration.pomodoroBreakMinutes),
            pomodoroRoundsPerSet: min(max(2, configuration.pomodoroRoundsPerSet), 4),
            pomodoroLongBreakMinutes: max(1, configuration.pomodoroLongBreakMinutes),
            pomodoroEyeBreakEnabled: configuration.pomodoroEyeBreakEnabled,
            mergeEyeBreakThresholdSeconds: max(0, configuration.mergeEyeBreakThresholdSeconds)
        )
    }

    private func beginFocus() {
        phase = .focus
        focusSecondsRemaining = configuration.initialFocusSeconds
        phaseSecondsLeft = focusSecondsRemaining
        emitTick()
    }

    private func beginBreak(_ kind: RhythmBreakKind) {
        phase = .breakTime(kind)
        switch kind {
        case .eye:
            phaseSecondsLeft = configuration.eyeBreakSeconds
        case .pomodoro:
            phaseSecondsLeft = configuration.pomodoroBreakSeconds
        case .pomodoroLong:
            phaseSecondsLeft = configuration.pomodoroLongBreakSeconds
        }
        emitTick()
    }

    private func scheduleMainTimerIfNeeded() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.advanceOneSecond()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func advanceOneSecond() {
        switch phase {
        case .focus:
            advanceFocus()
        case .breakTime:
            advanceBreak()
        }
    }

    private func advanceFocus() {
        focusSecondsRemaining -= 1
        phaseSecondsLeft = focusSecondsRemaining

        if focusSecondsRemaining <= 0 {
            stop()
            if configuration.mode == .pomodoro {
                completedPomodoroRounds += 1
                let kind: RhythmBreakKind = completedPomodoroRounds >= configuration.pomodoroRoundsPerSet ? .pomodoroLong : .pomodoro
                beginBreak(kind)
                onBreakTriggered?(kind)
            } else {
                beginBreak(.eye)
                onBreakTriggered?(.eye)
            }
            return
        }

        emitTick()
    }

    private func advanceBreak() {
        phaseSecondsLeft -= 1
        if phaseSecondsLeft <= 0 {
            stop()
            emitTick()
            return
        }
        emitTick()
    }

    private func emitTick() {
        onTick?(
            RhythmTick(
                phase: phase,
                secondsLeft: max(0, phaseSecondsLeft),
                focusSecondsRemaining: max(0, focusSecondsRemaining),
                completedPomodoroRounds: completedPomodoroRounds
            )
        )
    }
}
