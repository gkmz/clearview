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

}
