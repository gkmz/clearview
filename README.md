# ClearView

English | [简体中文](README.zh-CN.md)

[![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-blue)](#requirements)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange)](#development)
[![License](https://img.shields.io/badge/license-Apache--2.0-green)](LICENSE)

ClearView is a lightweight macOS eye-care reminder app that helps users keep healthier screen-time rhythms.

> Version: `0.1.0` (release)

## Highlights
- Menu bar based workflow with independent main panel.
- Reminder lifecycle: work timer -> preparation -> break -> completion.
- Reminder actions: complete, snooze, restart.
- Blue light filter presets: Off / Light / Medium / Night.
- Multiple customizable global shortcuts.
- Local-only persistence via `UserDefaults`.

## Requirements
- macOS 13+
- Xcode 15+ (recommended)
- Swift Package Manager

## Quick Start
1. Open Xcode.
2. `File -> Open...` and select `Package.swift`.
3. Run target `ClearViewApp`.
4. Click the menu bar icon and choose `打开 ClearView`.

## Documentation
- [Docs Index](docs/README.md)
- [Changelog](docs/CHANGELOG.md)
- [Contributing Guide](CONTRIBUTING.md)
- [Security Policy](SECURITY.md)

## Development

### Project Layout
- `Sources/ClearViewApp/AppEntry.swift`: app state and orchestration
- `Sources/ClearViewApp/ContentView.swift`: main UI
- `Sources/ClearViewApp/ReminderFloatingView.swift`: reminder popup UI
- `Sources/ClearViewApp/GlobalShortcutManager.swift`: global hotkeys
- `Sources/ClearViewApp/AppSettingsStore.swift`: persistence and migration
- `Sources/ClearViewApp/AboutPanelController.swift`: about panel
- `Sources/ClearViewApp/SettingsPanelController.swift`: settings panel

### Build
Open `Package.swift` in Xcode and run `ClearViewApp`.

## Contributing
Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) before submitting a PR.

## Support
If you encounter an issue, open a GitHub issue with:
- macOS version
- ClearView version
- reproduction steps
- expected vs actual behavior

## Privacy
- No account system
- No cloud sync
- No telemetry in `v0.1.0`

## License
Licensed under Apache License 2.0. See [LICENSE](LICENSE).
