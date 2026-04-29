# ClearView

[English](README.md) | 简体中文

[![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-blue)](#环境要求)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange)](#开发)
[![License](https://img.shields.io/badge/license-Apache--2.0-green)](LICENSE)

ClearView 是一款轻量的 macOS 护眼提醒工具，帮助你在长时间屏幕工作中保持更健康的休息节奏。

> 当前版本：`0.1.0`（release）

## 功能亮点
- 菜单栏驱动 + 独立主面板。
- 提醒流程：工作倒计时 -> 准备倒计时 -> 休息倒计时 -> 完成确认。
- 提醒操作：完成、稍后提醒、重置。
- 蓝光过滤档位：原色 / 轻柔 / 舒缓 / 夜间。
- 多个全局快捷键可自定义。
- 本地持久化（`UserDefaults`）。

## 环境要求
- macOS 13+
- Xcode 15+（推荐）
- Swift Package Manager

## 快速开始
1. 打开 Xcode。
2. `File -> Open...` 选择仓库里的 `Package.swift`。
3. 运行 `ClearViewApp` target。
4. 点击菜单栏图标，选择 `打开 ClearView`。

## 文档
- [文档索引](docs/README.md)
- [变更记录](docs/CHANGELOG.md)
- [贡献指南](CONTRIBUTING.md)
- [安全策略](SECURITY.md)

## 开发

### 项目结构
- `Sources/ClearViewApp/AppEntry.swift`：应用状态与编排
- `Sources/ClearViewApp/ContentView.swift`：主界面
- `Sources/ClearViewApp/ReminderFloatingView.swift`：提醒弹窗
- `Sources/ClearViewApp/GlobalShortcutManager.swift`：全局快捷键
- `Sources/ClearViewApp/AppSettingsStore.swift`：配置持久化与兼容迁移
- `Sources/ClearViewApp/AboutPanelController.swift`：关于窗
- `Sources/ClearViewApp/SettingsPanelController.swift`：设置窗

### 构建
在 Xcode 中打开 `Package.swift` 并运行 `ClearViewApp`。

## 贡献
欢迎提交 Issue 和 PR。提交前请先阅读 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 支持
如遇问题，请提交 Issue，并附上：
- macOS 版本
- ClearView 版本
- 复现步骤
- 期望结果与实际结果

## 隐私
- 不需要账号
- 不做云同步
- `v0.1.0` 不包含遥测上报

## 许可证
本项目采用 Apache License 2.0，详见 [LICENSE](LICENSE)。
