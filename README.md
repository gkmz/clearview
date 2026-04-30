# ClearView

English | [简体中文](README.zh-CN.md)

[![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-blue)](#requirements)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange)](#requirements)
[![License](https://img.shields.io/badge/license-Apache--2.0-green)](LICENSE)

ClearView is a lightweight macOS menu bar app that helps users maintain healthier screen-time rhythms with periodic eye-break reminders and blue-light filter controls.

> Current version: `0.1.0` (`release`)

## Table of Contents
- [Features](#features)
- [Requirements](#requirements)
- [Quick Start (Xcode)](#quick-start-xcode)
- [Build and Test](#build-and-test)
- [Project Structure](#project-structure)
- [Configuration and Data](#configuration-and-data)
- [Troubleshooting](#troubleshooting)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [Security](#security)
- [Privacy](#privacy)
- [License](#license)

## Features
- Menu bar based workflow with an independent main panel.
- Reminder lifecycle: work timer → preparation countdown → break countdown → completion.
- Reminder actions: complete now, snooze, and restart timing.
- Blue-light filter presets: `Off`, `Light`, `Medium`, `Night`.
- Multiple customizable global shortcuts.
- Local-only settings persistence via `UserDefaults`.

## Requirements
- macOS 13+
- Xcode 15+ (recommended)
- Swift 5.9+

## Quick Start (Xcode)
1. Open `ClearView.xcodeproj` in Xcode.
2. Select scheme `ClearView`.
3. Run (`⌘R`).
4. Click the menu bar icon and choose **打开 ClearView**.

## Build and Test

### Xcode
- Build: `Product -> Build`
- Run: `Product -> Run`
- Test: `Product -> Test`
- Archive: `Product -> Archive`

### Command Line (SwiftPM)
```bash
swift build
swift test
```

## Project Structure

```text
ClearView/
├── ClearView/                    # App source code
│   ├── ClearViewApp.swift        # App entry + app state orchestration
│   ├── MenuBarView.swift         # Menu bar menu UI
│   ├── ContentView.swift         # Main panel UI
│   ├── ReminderFloatingView.swift# Reminder popup UI
│   ├── GlobalShortcutManager.swift
│   ├── AppSettingsStore.swift    # Settings persistence + migration
│   ├── BlueLightFilterService.swift
│   ├── MainPanelController.swift
│   ├── SettingsPanelController.swift
│   ├── AboutPanelController.swift
│   ├── AppVersion.swift
│   └── Resources/                # Image assets (menu bar icon, backgrounds)
├── ClearViewTests/               # Unit tests
├── ClearViewUITests/             # UI tests
├── docs/
│   ├── README.md
│   └── CHANGELOG.md
├── CONTRIBUTING.md
├── SECURITY.md
├── Package.swift
└── LICENSE
```

## Configuration and Data
- User settings are stored locally in `UserDefaults`.
- No account system, cloud sync, or telemetry in `v0.1.0`.
- Shortcut and UI preference migrations are handled in `AppSettingsStore`.

## Troubleshooting
- **Menu bar icon not clear enough**: ensure the menu bar icon asset is a dedicated template-style icon (transparent background, simplified thick strokes).
- **Global shortcut registration fails**: choose another key combination in settings (some combos are reserved by macOS or other apps).
- **First launch blocked by macOS**: right-click `ClearView.app` and choose **Open** to confirm once.

## Roadmap
See [docs/CHANGELOG.md](docs/CHANGELOG.md) for release notes and upcoming evolution from current baseline.

## Contributing
Contributions are welcome.

Before opening a PR, please read [CONTRIBUTING.md](CONTRIBUTING.md).

Recommended PR checklist:
- Keep changes focused and small.
- Update docs when behavior changes.
- Ensure build and tests pass.
- Avoid committing secrets or local environment files.

## Security
If you discover a vulnerability, please follow [SECURITY.md](SECURITY.md) and report it privately first.

## Privacy
- No account system.
- No cloud sync.
- No telemetry in `v0.1.0`.

## License
Licensed under Apache License 2.0. See [LICENSE](LICENSE).
