# ClearView

[English](README.md) | 简体中文

[![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-blue)](#环境要求)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange)](#环境要求)
[![License](https://img.shields.io/badge/license-Apache--2.0-green)](LICENSE)

![](./docs/img/light-sy.png)

ClearView 是一款极简的 macOS 菜单栏护眼应用，帮助你通过周期性休息提醒与蓝光过滤控制，建立更健康的屏幕使用节奏。

> 当前版本：`0.1.0`（`release`）

## 目录
- [ClearView](#clearview)
  - [目录](#目录)
  - [功能特性](#功能特性)
  - [环境要求](#环境要求)
  - [安装使用](#安装使用)
    - [从 Release 下载](#从-release-下载)
    - [跳过 Gatekeeper 拦截](#跳过-gatekeeper-拦截)
    - [开始使用](#开始使用)
    - [默认快捷键](#默认快捷键)
  - [快速开始（Xcode）](#快速开始xcode)
  - [构建与测试](#构建与测试)
    - [Xcode](#xcode)
    - [打包 DMG](#打包-dmg)
  - [项目结构](#项目结构)
  - [配置与数据](#配置与数据)
  - [常见问题](#常见问题)
  - [路线图](#路线图)
  - [贡献](#贡献)
  - [安全](#安全)
  - [隐私](#隐私)
  - [界面](#界面)
  - [许可证](#许可证)

## 功能特性
- 极简风格，支持深色和浅色两种模式，跟随系统。
- 菜单栏驱动工作流，配合独立主面板。
- 提醒流程：工作倒计时 → 准备倒计时 → 休息倒计时 → 完成确认。
- 提醒操作：立即完成、稍后提醒、重启计时。
- 支持护眼与番茄两种节奏：番茄模式可在专注中插入护眼微休息，并在接近番茄休息时自动合并提醒。
- 蓝光过滤档位：`原色`、`轻柔`、`舒缓`、`夜间`。
- 支持多个全局快捷键自定义。
- 通过 `UserDefaults` 进行本地持久化。

## 环境要求
- macOS 13+

如果你只是安装使用，不需要安装 Xcode 或 Swift。

## 安装使用

### 从 Release 下载
1. 打开本仓库的 **Releases** 页面。
2. 下载最新版本的 `ClearView-<版本>.dmg`。
3. 双击打开 DMG。
4. 将 `ClearView.app` 拖到「应用程序」文件夹。
5. 在「应用程序」中启动 `ClearView`。

### 跳过 Gatekeeper 拦截
当前发布包可能没有经过 Apple 开发者签名和公证，首次启动时 macOS 可能提示“Apple 无法检查其是否包含恶意软件”或“无法打开”。

推荐方式：
1. 打开 Finder 的「应用程序」。
2. 找到 `ClearView.app`，按住 `Control` 点击，或右键点击。
3. 选择「打开」。
4. 在确认弹窗中再次点击「打开」。

如果仍然被拦截，请在系统设置中允许它运行：
1. 先尝试从「应用程序」启动一次 `ClearView`，让 macOS 生成拦截记录。
2. 打开「系统设置」。
3. 进入「隐私与安全性」。
4. 向下滚动到「安全性」区域。
5. 找到类似“已阻止使用 `ClearView`，因为它来自身份不明的开发者”的提示。
6. 点击「仍要打开」或「允许打开」。
7. 按系统要求输入 Mac 登录密码，或使用 Touch ID 确认。
8. 回到「应用程序」再次启动 `ClearView`，并在弹窗中点击「打开」。

不推荐直接关闭 Gatekeeper。只在你确认下载来源可信时使用上述方式放行本应用。

### 开始使用
启动后，`ClearView` 会出现在 macOS 菜单栏。点击菜单栏图标，可以打开主面板、调整提醒节奏、切换蓝光过滤档位和进入设置。

在「节奏」设置中可以选择：
- **护眼**：按设定间隔提醒你远眺休息。
- **番茄**：按番茄专注/休息周期运行，并可在专注阶段启用护眼微休息。

番茄模式中，如果护眼提醒与番茄休息时间接近，ClearView 会把护眼提醒合并到番茄休息开始阶段，避免连续弹出“20 秒护眼 + 5 分钟休息”的重复打断。

### 默认快捷键
默认快捷键如下，可在设置中自行修改：

| 功能 | 快捷键 |
| --- | --- |
| 打开主界面 | `⌘⇧Space` |
| 暂停/继续提醒 | `⌘⇧P` |
| 稍后提醒 | `⌘⇧S` |
| 切换护眼模式 | `⌘⇧L` |

## 快速开始（Xcode）
以下步骤面向开发者。

环境要求：
- Xcode 15+（推荐）
- Swift 5.9+

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

### 打包 DMG
在仓库根目录执行（会先 `xcodebuild` Release，再生成 `dist/ClearView-<版本>.dmg`，版本取自构建产物里的 `CFBundleShortVersionString`）：

```bash
./scripts/create-dmg.sh
```

若你已在 Xcode 里编译出 `ClearView.app`，可直接指定路径，跳过编译：

```bash
./scripts/create-dmg.sh /绝对路径/ClearView.app
```

默认打包流程使用 `CODE_SIGNING_ALLOWED=NO`。若要对外分发，需在 Xcode 中配置签名与公证，并调整打包流程。

> 构建策略：`v0.1.0` 仅支持通过 Xcode / `xcodebuild` 构建，以确保产出完整的 macOS `.app` 包（图标资源、Bundle 元信息与打包流程）。

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
- **首次启动被系统拦截**：参考 [跳过 Gatekeeper 拦截](#跳过-gatekeeper-拦截)，右键 `ClearView.app` 选择「打开」，确认一次即可。

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

## 界面

![](./docs/img/dark-sy.png)
![](./docs/img/dark-hy.png)
![](./docs/img/notice.png)
![](./docs/img/settings.png)

## 许可证
本项目采用 Apache License 2.0，详见 [LICENSE](LICENSE)。
