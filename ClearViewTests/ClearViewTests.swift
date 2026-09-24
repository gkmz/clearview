//
//  ClearViewTests.swift
//  ClearViewTests
//
//  Created by mo on 30.4.2026.
//

import Testing
import Foundation
import AppKit
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
        #expect(settings.pomodoroRoundsPerSet == 4)
        #expect(settings.pomodoroLongBreakMinutes == 15)
        #expect(settings.pomodoroEyeBreakEnabled == true)
        #expect(settings.mergeEyeBreakThresholdSeconds == 120)
        #expect(settings.launchAtLoginEnabled == false)
        #expect(settings.startTimerOnLaunch == true)
        #expect(settings.shortcutToggleRhythmModeKeyCode == ShortcutAction.toggleRhythmMode.defaultBinding.keyCode)
        #expect(settings.shortcutToggleRhythmModeModifierFlagsRaw == ShortcutAction.toggleRhythmMode.defaultBinding.modifierFlagsRaw)
        #expect(settings.backgroundImageModeKey == BackgroundImageMode.system.rawValue)
        #expect(settings.fixedBackgroundIsDark == false)
        #expect(settings.customLightBackgroundFileName == nil)
        #expect(settings.customDarkBackgroundFileName == nil)
    }

    @Test func backgroundImageStoreImportsAndReportsResolution() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ClearViewTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let sourceURL = temporaryDirectory.appendingPathComponent("source.png")
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: 5000,
            pixelsHigh: 1000,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )!
        try bitmap.representation(using: .png, properties: [:])!.write(to: sourceURL)

        let store = BackgroundImageStore(directoryURL: temporaryDirectory.appendingPathComponent("Backgrounds"))
        let result = try store.importImage(from: sourceURL, for: .light)

        #expect(result.pixelWidth == 5000)
        #expect(result.pixelHeight == 1000)
        #expect(!result.isLowResolution)
        let importedImage = store.image(for: .light)
        #expect(importedImage?.representations.first?.pixelsWide == 4096)
        #expect(importedImage?.representations.first?.pixelsHigh == 819)
    }

    @Test @MainActor func timeContextUsesWarmLateNightCopy() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 8 * 60 * 60)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 8, day: 11, hour: 1))!

        let context = TimeContext.current(date: date, calendar: calendar)

        #expect(context == .lateNight)
        #expect(context.greeting.contains("早点休息"))
        #expect(context.restingMessage.contains("早点睡"))
    }

    @Test func backgroundModesHaveConciseUserFacingTitles() {
        #expect(BackgroundImageMode.allCases.map(\.title) == ["跟随系统", "按时间切换", "固定"])
    }

    @Test @MainActor func rhythmConfigurationKeepsPomodoroDefaultsDistinctFromEyeBreaks() {
        let settings = AppSettings.default

        #expect(RhythmMode.fromSettingsKey(settings.rhythmModeKey) == .eyeCare)
        #expect(settings.eyeIntervalMinutes == 20)
        #expect(settings.eyeBreakDurationSeconds == 20)
        #expect(settings.pomodoroFocusMinutes == 25)
        #expect(settings.pomodoroBreakMinutes == 5)
        #expect(settings.pomodoroRoundsPerSet == 4)
        #expect(settings.pomodoroLongBreakMinutes == 15)
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

    @Test func pomodoroUsesConfiguredLongBreakAfterRoundThreshold() {
        let service = ReminderService()
        let configuration = RhythmConfiguration(
            mode: .pomodoro,
            eyeIntervalMinutes: 20,
            eyeBreakDurationSeconds: 20,
            pomodoroFocusMinutes: 1,
            pomodoroBreakMinutes: 1,
            pomodoroRoundsPerSet: 2,
            pomodoroLongBreakMinutes: 15,
            pomodoroEyeBreakEnabled: true,
            mergeEyeBreakThresholdSeconds: 120
        )
        var breaks: [RhythmBreakKind] = []
        service.onBreakTriggered = { breaks.append($0) }
        service.start(configuration: configuration)
        service.stop()
        for _ in 0..<60 { service.advanceOneSecondForTesting() }
        #expect(breaks == [.pomodoro])
        service.completeBreak()
        service.stop()
        for _ in 0..<60 { service.advanceOneSecondForTesting() }
        #expect(breaks == [.pomodoro, .pomodoroLong])
        #expect(service.completedPomodoroRounds == 2)
        service.completeBreak()
        #expect(service.completedPomodoroRounds == 0)
    }

    @Test func snoozingLongBreakKeepsPomodoroRoundCount() {
        let service = ReminderService()
        let configuration = RhythmConfiguration(
            mode: .pomodoro,
            eyeIntervalMinutes: 20,
            eyeBreakDurationSeconds: 20,
            pomodoroFocusMinutes: 1,
            pomodoroBreakMinutes: 1,
            pomodoroRoundsPerSet: 2,
            pomodoroLongBreakMinutes: 15,
            pomodoroEyeBreakEnabled: true,
            mergeEyeBreakThresholdSeconds: 120
        )

        service.start(configuration: configuration)
        service.stop()
        for _ in 0..<60 { service.advanceOneSecondForTesting() }
        service.completeBreak()
        service.stop()
        for _ in 0..<60 { service.advanceOneSecondForTesting() }

        #expect(service.completedPomodoroRounds == 2)
        service.snooze(minutes: 5)
        #expect(service.completedPomodoroRounds == 2)
    }

    @Test func pomodoroFourRoundDefaultKeepsFirstThreeBreaksShort() {
        let service = ReminderService()
        let configuration = RhythmConfiguration(
            mode: .pomodoro,
            eyeIntervalMinutes: 20,
            eyeBreakDurationSeconds: 20,
            pomodoroFocusMinutes: 1,
            pomodoroBreakMinutes: 1,
            pomodoroRoundsPerSet: 4,
            pomodoroLongBreakMinutes: 15,
            pomodoroEyeBreakEnabled: true,
            mergeEyeBreakThresholdSeconds: 120
        )
        var breaks: [RhythmBreakKind] = []
        service.onBreakTriggered = { breaks.append($0) }
        service.start(configuration: configuration)
        service.stop()
        for round in 0..<4 {
            for _ in 0..<60 { service.advanceOneSecondForTesting() }
            if round < 3 { service.completeBreak() }
            service.stop()
        }
        #expect(breaks == [.pomodoro, .pomodoro, .pomodoro, .pomodoroLong])
    }

    @Test func pomodoroConfigurationUpdateAppliesWithoutRestartingCurrentFocus() {
        let service = ReminderService()
        var configuration = RhythmConfiguration(
            mode: .pomodoro,
            eyeIntervalMinutes: 20,
            eyeBreakDurationSeconds: 20,
            pomodoroFocusMinutes: 1,
            pomodoroBreakMinutes: 5,
            pomodoroRoundsPerSet: 4,
            pomodoroLongBreakMinutes: 15,
            pomodoroEyeBreakEnabled: true,
            mergeEyeBreakThresholdSeconds: 120
        )
        var lastTick: RhythmTick?
        service.onTick = { lastTick = $0 }
        service.start(configuration: configuration)
        service.stop()
        service.advanceOneSecondForTesting()
        #expect(lastTick?.focusSecondsRemaining == 59)

        configuration.pomodoroBreakMinutes = 10
        service.updateConfiguration(configuration)
        #expect(lastTick?.focusSecondsRemaining == 59)

        for _ in 0..<59 { service.advanceOneSecondForTesting() }
        #expect(lastTick?.phase == .breakTime(.pomodoro))
        #expect(lastTick?.secondsLeft == 10 * 60)
    }

    @Test @MainActor func rhythmModeSwitchRefreshesDisplayedCountdownWhenPaused() {
        let appState = AppState()
        appState.updateRhythmMode(.eyeCare)
        appState.toggleReminder(false)

        appState.updateRhythmMode(.pomodoro)

        #expect(appState.reminderEnabled == false)
        #expect(appState.secondsUntilBreak == appState.pomodoroFocusMinutes * 60)
    }

    @Test @MainActor func launchDisplaysConfiguredPomodoroDurationWhenAutoStartIsDisabled() throws {
        let defaults = UserDefaults.standard
        let settingsKey = "clearview.app.settings.v1"
        let previousSettings = defaults.data(forKey: settingsKey)
        defer {
            if let previousSettings {
                defaults.set(previousSettings, forKey: settingsKey)
            } else {
                defaults.removeObject(forKey: settingsKey)
            }
        }

        var settings = AppSettings.default
        settings.rhythmModeKey = RhythmMode.pomodoro.settingsKey
        settings.pomodoroFocusMinutes = 25
        settings.startTimerOnLaunch = false
        AppSettingsStore(defaults: defaults).save(settings)

        let appState = AppState(
            blueLightService: BlueLightFilterService(),
            settingsStore: AppSettingsStore(defaults: defaults)
        )

        #expect(appState.rhythmMode == .pomodoro)
        #expect(appState.reminderEnabled == false)
        #expect(appState.secondsUntilBreak == 25 * 60)
    }

    @Test @MainActor func pomodoroSettingsRefreshPausedFocusAndActiveBreakDurations() {
        let appState = AppState()
        appState.updateRhythmMode(.pomodoro)
        appState.toggleReminder(false)

        appState.updatePomodoroFocus(45)
        #expect(appState.secondsUntilBreak == 45 * 60)

        appState.activeBreakKind = .pomodoro
        appState.reminderPhase = .pomodoroResting
        appState.breakSecondsLeft = 5 * 60
        appState.updatePomodoroBreak(10)
        #expect(appState.breakSecondsLeft == 10 * 60)

        appState.activeBreakKind = .pomodoroLong
        appState.updatePomodoroLongBreak(30)
        #expect(appState.breakSecondsLeft == 30 * 60)
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
        appState.advanceReminderOneSecondForTesting()
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

    @Test @MainActor func restoringDefaultsResetsPomodoroSettingsAndRound() {
        let appState = AppState()
        appState.updatePomodoroRoundsPerSet(2)
        appState.updatePomodoroLongBreak(30)
        appState.completedPomodoroRounds = 1

        appState.restoreDefaultSettings()

        #expect(appState.pomodoroRoundsPerSet == 4)
        #expect(appState.pomodoroLongBreakMinutes == 15)
        #expect(appState.completedPomodoroRounds == 0)
        #expect(appState.rhythmMode == .eyeCare)
    }

}
