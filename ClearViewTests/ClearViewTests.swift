//
//  ClearViewTests.swift
//  ClearViewTests
//
//  Created by mo on 30.4.2026.
//

import Testing
import Foundation
@testable import ClearView

struct ClearViewTests {

    @Test @MainActor func appSettingsDecodeLegacyRhythmValues() throws {
        let json = """
        {
          "reminderEnabled": true,
          "workIntervalMinutes": 25,
          "breakDurationSeconds": 40,
          "filterLevelKey": "off",
          "useBackgroundImage": true,
          "playBreakFinishedSound": false,
          "shortcutKeyCode": 49,
          "shortcutModifierFlagsRaw": 1179648,
          "backgroundImageOpacity": 1.0,
          "mainWindowOpacity": 0.8,
          "reminderWindowOpacity": 0.78,
          "settingsWindowOpacity": 0.78
        }
        """.data(using: .utf8)!

        let settings = try JSONDecoder().decode(AppSettings.self, from: json)

        #expect(settings.rhythmModeKey == RhythmMode.eyeCare.settingsKey)
        #expect(settings.eyeIntervalMinutes == 25)
        #expect(settings.eyeBreakDurationSeconds == 40)
        #expect(settings.pomodoroFocusMinutes == 25)
        #expect(settings.pomodoroBreakMinutes == 5)
        #expect(settings.pomodoroEyeBreakEnabled == true)
        #expect(settings.mergeEyeBreakThresholdSeconds == 120)
        #expect(settings.launchAtLoginEnabled == false)
        #expect(settings.startTimerOnLaunch == true)
        #expect(settings.shortcutToggleRhythmModeKeyCode == ShortcutAction.toggleRhythmMode.defaultBinding.keyCode)
        #expect(settings.shortcutToggleRhythmModeModifierFlagsRaw == ShortcutAction.toggleRhythmMode.defaultBinding.modifierFlagsRaw)
    }

    @Test @MainActor func rhythmConfigurationKeepsPomodoroDefaultsDistinctFromEyeBreaks() {
        let settings = AppSettings.default

        #expect(RhythmMode.fromSettingsKey(settings.rhythmModeKey) == .eyeCare)
        #expect(settings.eyeIntervalMinutes == 20)
        #expect(settings.eyeBreakDurationSeconds == 20)
        #expect(settings.pomodoroFocusMinutes == 25)
        #expect(settings.pomodoroBreakMinutes == 5)
        #expect(settings.pomodoroEyeBreakEnabled)
    }

    @Test @MainActor func pomodoroFocusDoesNotInsertEyeBreaks() {
        let service = ReminderService()
        let configuration = RhythmConfiguration(
            mode: .pomodoro,
            eyeIntervalMinutes: 1,
            eyeBreakDurationSeconds: 5,
            pomodoroFocusMinutes: 1,
            pomodoroBreakMinutes: 1,
            pomodoroEyeBreakEnabled: true,
            mergeEyeBreakThresholdSeconds: 0
        )
        var triggeredBreaks: [RhythmBreakKind] = []

        service.onBreakTriggered = { kind in
            triggeredBreaks.append(kind)
        }

        service.start(configuration: configuration)
        service.stop()
        for _ in 0..<60 {
            service.advanceOneSecondForTesting()
        }
        service.stop()

        #expect(triggeredBreaks == [.pomodoro])
    }

    @Test @MainActor func rhythmModeSwitchRefreshesDisplayedCountdownWhenPaused() {
        let appState = AppState()
        appState.updateRhythmMode(.eyeCare)
        appState.toggleReminder(false)

        appState.updateRhythmMode(.pomodoro)

        #expect(appState.reminderEnabled == false)
        #expect(appState.secondsUntilBreak == appState.pomodoroFocusMinutes * 60)
    }

    @Test @MainActor func testReminderPreviewDoesNotChangeMainCountdown() {
        let appState = AppState()
        appState.updateRhythmMode(.eyeCare)
        appState.toggleReminder(false)
        appState.updateInterval(45)
        let secondsBeforePreview = appState.secondsUntilBreak
        let reminderEnabledBeforePreview = appState.reminderEnabled

        appState.triggerTestReminderNow()

        #expect(appState.isReminderPreview)
        #expect(appState.secondsUntilBreak == secondsBeforePreview)
        #expect(appState.reminderEnabled == reminderEnabledBeforePreview)
    }

    @Test @MainActor func resumeReminderKeepsPausedCountdown() async {
        let appState = AppState()
        appState.updateRhythmMode(.eyeCare)
        appState.toggleReminder(true)
        appState.updateInterval(20)
        appState.reminderService.advanceOneSecondForTesting()
        await Task.yield()
        appState.toggleReminder(false)
        let pausedSeconds = appState.secondsUntilBreak

        appState.toggleReminder(true)

        #expect(appState.reminderEnabled)
        #expect(appState.secondsUntilBreak == pausedSeconds)
        #expect(appState.secondsUntilBreak < appState.workIntervalMinutes * 60)
    }

    @Test @MainActor func toggleRhythmModeSwitchesBetweenEyeCareAndPomodoro() {
        let appState = AppState()
        appState.updateRhythmMode(.eyeCare)

        appState.toggleRhythmMode()
        #expect(appState.rhythmMode == .pomodoro)

        appState.toggleRhythmMode()
        #expect(appState.rhythmMode == .eyeCare)
    }

    @Test @MainActor func breakCanContinueAfterMinimumEyeRelaxTime() {
        let appState = AppState()
        appState.activeBreakKind = .pomodoro
        appState.pomodoroBreakMinutes = 5
        appState.reminderPhase = .pomodoroResting
        appState.breakSecondsLeft = 281

        #expect(appState.canCompleteCurrentBreak == false)

        appState.breakSecondsLeft = 280
        #expect(appState.canCompleteCurrentBreak == true)

        appState.reminderPhase = .preparing
        #expect(appState.canCompleteCurrentBreak == false)
    }

}
