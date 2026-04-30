# ClearView

[English](README.md) | 简体中文

[![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-blue)](#环境要求)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange)](#环境要求)
[![License](https://img.shields.io/badge/license-Apache--2.0-green)](LICENSE)

ClearView 是一款轻量的 macOS 菜单栏护眼应用，帮助你通过周期性休息提醒与蓝光过滤控制，建立更健康的屏幕使用节奏。

> 当前版本：`0.1.0`（`release`）

## 目录
- [功能特性](#功能特性)
- [环境要求](#环境要求)
- [快速开始（Xcode）](#快速开始xcode)
- [构建与测试](#构建与测试)
- [项目结构](#项目结构)
- [配置与数据](#配置与数据)
- [常见问题](#常见问题)
- [路线图](#路线图)
- [贡献](#贡献)
- [安全](#安全)
- [隐私](#隐私)
- [许可证](#许可证)

## 功能特性
- 菜单栏驱动工作流，配合独立主面板。
- 提醒流程：工作倒计时 → 准备倒计时 → 休息倒计时 → 完成确认。
- 提醒操作：立即完成、稍后提醒、重启计时。
- 蓝光过滤档位：`原色`、`轻柔`、`舒缓`、`夜间`。
- 支持多个全局快捷键自定义。
- 通过 `UserDefaults` 进行本地持久化。

## 环境要求
- macOS 13+
- Xcode 15+（推荐）
- Swift 5.9+

## 快速开始（Xcode）
1. 用 Xcode 打开 `ClearView.xcodeproj`。
2. 选择 Scheme：`ClearView`。
3. 运行（`⌘R`）。
4. 点击菜单栏图标，选择 **打开 ClearView**。

## 构建与测试

### Xcode
- 构建：`Product -> Build`
- 运行：`Product -> Run`
- 测试：`Product -> Test`
- 归档：`Product -> Archive`

### 命令行（SwiftPM）
```bash
swift build
swift test
```

## 项目结构

```text
ClearView/
├── ClearView/                    # 应用源码
│   ├── ClearViewApp.swift        # 应用入口 + 全局状态编排
│   ├── MenuBarView.swift         # 菜单栏菜单 UI
│   ├── ContentView.swift         # 主面板 UI
│   ├── ReminderFloatingView.swift# 提醒弹窗 UI
│   ├── GlobalShortcutManager.swift
│   ├── AppSettingsStore.swift    # 设置持久化 + 兼容迁移
│   ├── BlueLightFilterService.swift
│   ├── MainPanelController.swift
│   ├── SettingsPanelController.swift
│   ├── AboutPanelController.swift
│   ├── AppVersion.swift
│   └── Resources/                # 图片资源（菜单栏图标、背景图）
├── ClearViewTests/               # 单元测试
├── ClearViewUITests/             # UI 测试
├── docs/
│   ├── README.md
│   └── CHANGELOG.md
├── CONTRIBUTING.md
├── SECURITY.md
├── Package.swift
└── LICENSE
```

## 配置与数据
- 用户设置仅保存在本地 `UserDefaults`。
- `v0.1.0` 不包含账号系统、云同步与遥测。
- 快捷键与界面偏好项的历史兼容迁移由 `AppSettingsStore` 处理。

## 常见问题
- **菜单栏图标不够清晰**：请使用“菜单栏专用模板图标”（透明背景、简化笔画、较粗线条）。
- **全局快捷键注册失败**：请在设置中更换快捷键组合（可能与 macOS 或其他应用冲突）。
- **首次启动被系统拦截**：右键 `ClearView.app` 选择“打开”，确认一次即可。

## 路线图
发布记录与后续演进方向见 [docs/CHANGELOG.md](docs/CHANGELOG.md)。

## 贡献
欢迎提交 Issue 与 PR。

提交前请先阅读 [CONTRIBUTING.md](CONTRIBUTING.md)。

推荐 PR 自检清单：
- 保持改动聚焦、规模可审查。
- 行为变化同步更新文档。
- 确认构建与测试通过。
- 不提交密钥或本地环境文件。

## 安全
若发现安全问题，请先按 [SECURITY.md](SECURITY.md) 进行私下披露。

## 隐私
- 不需要账号。
- 不进行云同步。
- `v0.1.0` 不包含遥测上报。

## 许可证
本项目采用 Apache License 2.0，详见 [LICENSE](LICENSE)。
