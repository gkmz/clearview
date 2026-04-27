# ClearView 第一版（macOS）

本目录包含一个可运行的第一版菜单栏应用代码，已实现：

- 数字时钟主界面（显示下次休息剩余时间）
- 休息提醒（可开关、可调间隔、倒计时、立即提醒）
- 三段式提醒（温和 -> 明确 -> 兜底）
- 休息倒计时结束后不会自动关闭，需要点击继续按钮后重新计时
- 重置计时后不会自动开始，需要手动点击开始按钮
- 设置项使用预设按钮：提醒间隔 20/25/45/60 分钟，休息时长 20/40/60/90 秒
- 蓝光过滤（关闭/轻度/中度/夜间）
- 测试入口（立即测试提醒、5秒后测试）
- 退出确认（点击退出图标后确认退出，并恢复默认色彩）
- 极简玻璃质感 UI（绿色小清新、无渐变、无 emoji）
- 设置为全局居中弹窗，主界面与按钮不透明度统一为 0.8
- 所有图标按钮支持鼠标悬停功能提示

## 代码结构

- `Sources/ClearViewApp/main.swift`：应用入口与状态管理
- `Sources/ClearViewApp/ContentView.swift`：菜单栏主界面
- `Sources/ClearViewApp/ReminderService.swift`：提醒计时逻辑
- `Sources/ClearViewApp/BlueLightFilterService.swift`：蓝光过滤逻辑
- `Package.swift`：Swift Package 定义

## 运行方式（推荐）

1. 打开 Xcode
2. `File -> Open...` 选择当前目录中的 `Package.swift`
3. 选择 `ClearViewApp` target 并运行
4. 启动后会直接弹出主窗口（同时在菜单栏也有入口）
5. 如需纯菜单栏体验，可关闭主窗口后通过菜单栏图标继续使用

> 如果 Xcode 提示 `@main attribute cannot be used in a module that contains top-level code`：  
> 请确认入口文件不是 `main.swift`。本项目已使用 `AppEntry.swift` 作为入口文件。

## 说明

- 蓝光过滤通过系统显示 Gamma 调整实现，恢复档位会调用系统默认色彩恢复。
- 休息提醒当前通过“请求用户注意 + 蜂鸣”触发（稳定优先，避免部分环境下通知中心崩溃）。
- 休息提醒会在屏幕顶部中间显示半透明浮窗，支持“完成 / 推迟5分钟 / 跳过”。
- 当前为 v1 验证版，后续可继续增加：
  - 智能暂停（活动检测）
  - 会议模式静默
  - 本地统计持久化与报告页

