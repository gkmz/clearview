# ClearView

English | [简体中文](README.zh-CN.md)

[![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-blue)](#system-requirements)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange)](#development)
[![License](https://img.shields.io/badge/license-Apache--2.0-green)](LICENSE)

ClearView is a lightweight macOS eye-care timer that helps users maintain healthy break rhythms during long screen-time sessions.

> 当前版本：`0.1.0`（MVP / 核心闭环验证版）

## Table of Contents
- [Features](#features)
- [System Requirements](#system-requirements)
- [Quick Start](#quick-start)
- [Usage](#usage)
- [Configuration & Privacy](#configuration--privacy)
- [Project Status](#project-status)
- [Known Limitations](#known-limitations)
- [Documentation](#documentation)
- [Development](#development)
- [Contributing](#contributing)
- [Support](#support)
- [Security](#security)
- [License](#license)

## Features

### Implemented in 0.1
- Menu bar workflow: open app, pause/resume reminders, trigger test reminder, quit.
- Reminder lifecycle: work timer → preparation countdown → break countdown → completion confirmation.
- Break actions: snooze, complete break, manual reset.
- Blue light filter presets: Off / Light / Medium / Night.
- Global shortcut customization (function keys can be standalone shortcuts).
- Local settings persistence via `UserDefaults`.

### UX Highlights
- Independent main panel (not constrained by menu popover).
- Lightweight floating reminder panel.
- Background image and opacity controls.

## System Requirements
- macOS 13+
- Xcode (recommended)
- Swift Package Manager

## Quick Start
1. Open Xcode.
2. `File -> Open...` and select `Package.swift` in this repository.
3. Run target `ClearViewApp`.
4. Click the ClearView icon in the menu bar.
5. Select **打开 ClearView**.

## Usage

### Reminder Flow
1. Start with default work interval (20 min) or trigger **试试提醒**.
2. Reminder enters preparation phase (5s), then break phase.
3. At break end, user confirms completion or chooses snooze.

### Pause / Resume (Already Supported)
- You can pause or resume reminders from the menu item **暂不打扰 / 继续提醒**.
- This is the current 0.1 “silent control” mechanism.

### Blue Light Filter
- Choose among Off / Light / Medium / Night.
- On app quit, display color is restored to default.

## Configuration & Privacy
- Settings are stored locally in `UserDefaults` key: `clearview.app.settings.v1`.
- No account system.
- No cloud sync.
- No remote telemetry in current 0.1 scope.

## Project Status
- Current milestone: `0.1` (MVP stabilization)
- Scope: focus on core usability and reliability of existing features

## Known Limitations
- No analytics/report dashboard yet.
- No automatic context-aware pause strategy yet (manual pause exists).
- No cross-device synchronization.

## Documentation
- [Documentation Index](docs/README.md)
- [Product Plan (0.1)](docs/PRODUCT_PLAN.md)
- [Release 0.1 Gap Checklist](docs/RELEASE_0.1_GAP.md)
- [Changelog](docs/CHANGELOG.md)

## Community
- [Contributing Guide](CONTRIBUTING.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Support](SUPPORT.md)
- [Security Policy](SECURITY.md)

## Contributing
- See [CONTRIBUTING.md](CONTRIBUTING.md)

## Support
- See [SUPPORT.md](SUPPORT.md)

## Security
- See [SECURITY.md](SECURITY.md)

## Development

### Project Structure
- `Sources/ClearViewApp/AppEntry.swift` – app state and reminder orchestration
- `Sources/ClearViewApp/ReminderService.swift` – reminder timer service
- `Sources/ClearViewApp/MenuBarView.swift` – menu bar actions
- `Sources/ClearViewApp/ContentView.swift` – main UI
- `Sources/ClearViewApp/BlueLightFilterService.swift` – blue light filter logic
- `Sources/ClearViewApp/AppSettingsStore.swift` – local settings persistence

### Build
Open `Package.swift` in Xcode and run `ClearViewApp`.

## License
MIT. See [LICENSE](LICENSE).
