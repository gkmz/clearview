# ClearView 第一版（macOS）

本目录包含一个可运行的第一版 macOS 应用代码，已实现：

- 数字时钟主界面（显示下次休息剩余时间）
- 菜单栏快捷入口（打开主界面、暂停/继续提醒、试试提醒、退出）
- 独立沉浸式主面板（不再依赖菜单窗口承载完整界面）
- Bonjourr 风格主界面骨架（深浅色背景图、当前时间、问候、护眼计时组件）
- 休息提醒（可开关、可调间隔、准备倒计时、休息倒计时、立即提醒）
- 休息倒计时结束后播放清脆提示音，并等待用户点击“休息好了”
- 重置计时后不会自动开始，需要手动点击开始按钮
- 设置项使用预设按钮：提醒间隔 20/25/45/60 分钟，休息时长 20/40/60/90 秒
- 蓝光过滤（原色/轻柔/舒缓/夜间）
- 测试入口（立即测试提醒）
- 极简护眼 UI（自动适配深色/浅色模式、无渐变、无 emoji）
- 设置为全局居中弹窗
- 所有图标按钮支持鼠标悬停功能提示

## 代码结构

- `Sources/ClearViewApp/AppEntry.swift`：应用入口与状态管理
- `Sources/ClearViewApp/MenuBarView.swift`：菜单栏快捷菜单
- `Sources/ClearViewApp/MainPanelController.swift`：独立主面板控制器
- `Sources/ClearViewApp/ContentView.swift`：沉浸式主界面
- `Sources/ClearViewApp/ReminderFloatingView.swift`：休息提醒浮窗
- `Sources/ClearViewApp/Resources/`：主界面背景图资源
- `Sources/ClearViewApp/ReminderService.swift`：提醒计时逻辑
- `Sources/ClearViewApp/BlueLightFilterService.swift`：蓝光过滤逻辑
- `Package.swift`：Swift Package 定义

## 运行方式（推荐）

1. 打开 Xcode
2. `File -> Open...` 选择当前目录中的 `Package.swift`
3. 选择 `ClearViewApp` target 并运行
4. 启动后点击菜单栏中的 ClearView 图标
5. 选择“打开 ClearView”显示独立主面板

> 如果 Xcode 提示 `@main attribute cannot be used in a module that contains top-level code`：  
> 请确认入口文件不是 `main.swift`。本项目已使用 `AppEntry.swift` 作为入口文件。

## 说明

- 蓝光过滤通过系统显示 Gamma 调整实现，恢复档位会调用系统默认色彩恢复。
- 休息提醒会在屏幕顶部偏下位置显示半透明浮窗，支持“稍后提醒 / 休息好了”。
- 菜单栏只作为快捷入口，主界面由自定义 `NSPanel` 承载，便于后续支持背景图和更完整的窗口效果。
- 主面板打开时会短暂前置，随后降回普通窗口层级，避免长期遮挡屏幕。
- 主界面背景会跟随系统深浅色切换：浅色使用秋景图，深色使用夜景图，并叠加遮罩保证文字可读性。
- 当前为 v1 验证版，后续可继续增加：
  - 智能暂停（活动检测）
  - 会议模式静默
  - 本地统计持久化与报告页

