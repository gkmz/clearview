# ClearView

[English](README.md) | 简体中文

[![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-blue)](#系统要求)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange)](#开发)
[![License](https://img.shields.io/badge/license-Apache--2.0-green)](LICENSE)

ClearView 是一款轻量的 macOS 护眼提醒工具，帮助用户在长时间屏幕工作中保持更健康的休息节奏。

> 当前版本：`0.1.0`（MVP / 核心闭环验证版）

## 目录
- [功能特性](#功能特性)
- [系统要求](#系统要求)
- [快速开始](#快速开始)
- [使用说明](#使用说明)
- [配置与隐私](#配置与隐私)
- [项目状态](#项目状态)
- [已知限制](#已知限制)
- [文档](#文档)
- [开发](#开发)
- [贡献](#贡献)
- [支持](#支持)
- [安全](#安全)
- [许可证](#许可证)

## 功能特性

### 0.1 已实现
- 菜单栏操作：打开应用、暂停/继续提醒、测试提醒、退出。
- 提醒生命周期：工作倒计时 → 准备倒计时 → 休息倒计时 → 完成确认。
- 休息操作：稍后提醒、完成休息、手动重置。
- 蓝光过滤预设：原色 / 轻柔 / 舒缓 / 夜间。
- 全局快捷键自定义（功能键可单独作为快捷键）。
- 使用 `UserDefaults` 进行本地设置持久化。

### 体验亮点
- 独立主面板（不受菜单弹窗限制）。
- 轻量提醒浮窗。
- 背景图与透明度可调。

## 系统要求
- macOS 13+
- Xcode（推荐）
- Swift Package Manager

## 快速开始
1. 打开 Xcode。
2. `File -> Open...` 选择仓库中的 `Package.swift`。
3. 运行 `ClearViewApp` target。
4. 点击菜单栏 ClearView 图标。
5. 选择 **打开 ClearView**。

## 使用说明

### 提醒流程
1. 使用默认工作间隔（20 分钟）或点击 **试试提醒**。
2. 进入准备阶段（5 秒），随后进入休息阶段。
3. 休息结束后确认完成或选择稍后提醒。

### 暂停/继续（当前已支持）
- 可通过菜单项 **暂不打扰 / 继续提醒** 手动暂停或恢复提醒。
- 这是 0.1 当前提供的“静默控制”机制。

### 蓝光过滤
- 可在原色 / 轻柔 / 舒缓 / 夜间中切换。
- 退出应用时会恢复系统默认色彩。

## 配置与隐私
- 设置本地存储于 `UserDefaults`：`clearview.app.settings.v1`。
- 当前版本不包含账号系统。
- 当前版本不包含云同步。
- 当前 0.1 范围不包含远程遥测。

## 项目状态
- 当前里程碑：`0.1`（MVP 稳定化）
- 范围重点：现有能力的可用性与稳定性

## 已知限制
- 暂无统计/报告面板。
- 暂无自动场景感知暂停策略（仅支持手动暂停）。
- 暂无跨设备同步。

## 文档
- [文档索引](docs/README.md)
- [产品规划（0.1）](docs/PRODUCT_PLAN.md)
- [0.1 发布缺口清单](docs/RELEASE_0.1_GAP.md)
- [变更记录](docs/CHANGELOG.md)

## 开发

### 项目结构
- `Sources/ClearViewApp/AppEntry.swift` – 应用状态与提醒编排
- `Sources/ClearViewApp/ReminderService.swift` – 提醒计时服务
- `Sources/ClearViewApp/MenuBarView.swift` – 菜单栏交互
- `Sources/ClearViewApp/ContentView.swift` – 主界面
- `Sources/ClearViewApp/BlueLightFilterService.swift` – 蓝光过滤逻辑
- `Sources/ClearViewApp/AppSettingsStore.swift` – 本地设置持久化

### 构建
在 Xcode 打开 `Package.swift` 并运行 `ClearViewApp`。

## 贡献
参见 [CONTRIBUTING.md](CONTRIBUTING.md)

## 支持
参见 [SUPPORT.md](SUPPORT.md)

## 安全
参见 [SECURITY.md](SECURITY.md)

## 许可证
MIT，详见 [LICENSE](LICENSE)。
