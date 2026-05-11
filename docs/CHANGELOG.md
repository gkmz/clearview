# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [0.2.0] - 2026-05-11

### Added
- Pomodoro rhythm mode with configurable focus and break durations.
- Simplified Pomodoro rhythm that keeps focus uninterrupted and guides eye relaxation at the start of rest.
- Launch-at-login and start-timer-on-launch preferences.
- Menu bar action and configurable global shortcut for switching between Eye Relax and Pomodoro rhythms.

### Changed
- Simplified rhythm settings around Eye Relax and Pomodoro so the two modes no longer compete for separate timers.
- Refined reminder intensity into distinct light, standard, and strict presentation behaviors.
- Improved reminder preview so test reminders do not affect the active countdown.
- Pause/resume now continues the existing countdown instead of restarting it.

### Developer Experience
- Added `scripts/dev.sh` for build, run, unit test, and full test commands.

## [0.1.0] - 2026-04-29

### Added
- Menu bar entry and standalone main panel experience.
- Eye-break reminder flow with preparation countdown and break countdown.
- Reminder floating panel with snooze/complete actions.
- Blue light filter levels (off/light/medium/night).
- Global shortcut configuration and persistence.
- Appearance and preference settings persistence via UserDefaults.

### Notes
- This release focuses on core usability and product validation.
- Advanced capabilities (automatic context-aware silence, analytics/reporting) are planned for future versions.
