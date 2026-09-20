# 番茄长休息 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 为番茄模式增加可配置的专注轮次和长休息，同时保留舒眼模式及现有短休息舒眼引导。

**Architecture:** 在 `ReminderService` 内维护番茄组的已完成轮次，并在专注结束时根据配置选择短休息或长休息；`AppState` 只负责将服务事件映射为弹窗阶段和展示文案。新增设置字段通过 `AppSettings`/`UserDefaults` 持久化，旧设置缺失时使用默认值。界面继续沿用现有节奏设置卡片和提醒弹窗结构。

**Tech Stack:** Swift 5.9、SwiftUI、AppKit、Swift Testing、UserDefaults。

## Global Constraints

- 后端主要使用 Go，前端主要使用 React；本项目为 macOS Swift 应用，遵循现有 Swift/SwiftUI 结构。
- 每段关键代码添加明确中文注释，公开方法添加文档注释。
- 不引入第三方依赖，不改变舒眼模式的现有规则。
- 番茄每组专注轮次仅允许 `2`、`3`、`4`，默认 `4`；长休息默认 `15` 分钟。
- 长休息开始时复用一次舒眼引导，不叠加额外舒眼弹窗。

## 文件结构

- Modify `ClearView/AppSettingsStore.swift`: 增加每组轮次和长休息分钟的 Codable 设置字段、默认值和兼容解码。
- Modify `ClearView/ReminderService.swift`: 增加长休息类型、轮次状态、配置归一化和测试可驱动的状态推进。
- Modify `ClearView/ClearViewApp.swift`: 暴露设置状态，连接服务轮次/休息类型，处理配置变更和长休息完成后的重置。
- Modify `ClearView/AppCopy.swift` and `ClearView/ReminderFloatingView.swift`: 增加短休息/长休息文案和轮次反馈。
- Modify `ClearView/ContentView.swift` and `ClearView/SettingsPanelController.swift`: 增加番茄轮次、长休息配置控件和当前轮次摘要。
- Modify `ClearViewTests/ClearViewTests.swift`: 覆盖默认值、2/3/4 轮边界、长休息时长、模式切换和兼容解码。
- Modify `README.zh-CN.md` and `README.md`: 更新番茄规则和配置说明。

### Task 1: 扩展设置模型与默认值

**Files:**
- Modify: `ClearView/AppSettingsStore.swift`
- Test: `ClearViewTests/ClearViewTests.swift`

**Interfaces:**
- Produces `pomodoroRoundsPerSet: Int` with default `4` and `pomodoroLongBreakMinutes: Int` with default `15`.
- AppSettings decoding missing either field must preserve these defaults.

- [ ] Write tests asserting defaults and decoding legacy JSON without the new keys.
- [ ] Run `xcodebuild -scheme ClearView -destination 'platform=macOS' test` and verify the new tests fail before implementation.
- [ ] Add Codable fields, default values, clamping (`2...4` rounds, positive long break), and include them in save/load paths.
- [ ] Run the focused test suite and verify PASS.
- [ ] Commit with `feat: persist pomodoro long break settings`.

### Task 2: Add service-level round and long-break state machine

**Files:**
- Modify: `ClearView/ReminderService.swift`
- Test: `ClearViewTests/ClearViewTests.swift`

**Interfaces:**
- Extend `RhythmConfiguration` with `pomodoroRoundsPerSet` and `pomodoroLongBreakMinutes`.
- Extend `RhythmBreakKind` with `.pomodoroLong` while retaining `.eye` and `.pomodoro` for compatibility.
- Expose `completedPomodoroRounds` and include break kind in `RhythmTick` so UI can identify long rest.

- [ ] Add failing tests for 2-round, 3-round, and 4-round sets, asserting short breaks before the threshold and long break at the threshold.
- [ ] Add failing tests for long-break seconds and reset to round zero after completing/skipping a break.
- [ ] Implement normalized configuration, increment only after focus reaches zero, select `.pomodoroLong` at the configured threshold, and reset after break completion.
- [ ] Keep eye-care mode behavior unchanged and ensure `forceTrigger(kind: .eye)` remains valid.
- [ ] Run focused service tests and the full unit suite.
- [ ] Commit with `feat: add pomodoro round state machine`.

### Task 3: Connect AppState and reminder flow

**Files:**
- Modify: `ClearView/ClearViewApp.swift`
- Modify: `ClearView/AppCopy.swift`
- Modify: `ClearView/ReminderFloatingView.swift`
- Test: `ClearViewTests/ClearViewTests.swift`

**Interfaces:**
- AppState publishes `pomodoroRoundsPerSet`, `pomodoroLongBreakMinutes`, and current round.
- `activeBreakKind` supports `.pomodoroLong`; `canCompleteCurrentBreak` uses the active break duration.

- [ ] Add failing tests for setting changes resetting the current round, switching to eye-care resetting the round, and long-break completion resetting the group.
- [ ] Add long-rest title/message/help copy distinct from short rest while preserving the first-stage eye-relax instruction.
- [ ] Map service ticks and break callbacks into AppState without starting duplicate timers or duplicate eye prompts.
- [ ] Persist new settings and reset service configuration when the user changes either setting.
- [ ] Run unit tests covering AppState transitions and reminder completion.
- [ ] Commit with `feat: connect pomodoro long breaks to reminder flow`.

### Task 4: Add settings and main-panel controls

**Files:**
- Modify: `ClearView/ContentView.swift`
- Modify: `ClearView/SettingsPanelController.swift`

**Interfaces:**
- Reuse existing `presetRow` and `rhythmSummaryCard` components.
- Round selector values are `[2, 3, 4]`; long-break selector values are `[15, 20, 30]`.

- [ ] Add controls under the Pomodoro card for “每组几轮” and “长休息多久”.
- [ ] Update the Pomodoro summary to show focus, short break, and configured set size.
- [ ] Show the current round and whether the next rest is short or long in the timer view when Pomodoro is active.
- [ ] Build the app and manually verify both main panel and standalone settings panel render without layout regressions.
- [ ] Commit with `feat: expose pomodoro long break controls`.

### Task 5: Documentation and full regression

**Files:**
- Modify: `README.zh-CN.md`
- Modify: `README.md`
- Test: `ClearViewTests/ClearViewTests.swift`, `ClearViewUITests/*` as needed

- [ ] Document the default 4-round behavior, configurable 2/3/4 rounds, short-break eye guidance, and 15-minute long break.
- [ ] Run `./scripts/dev.sh test`.
- [ ] Inspect `git diff` and `git status`, confirm no unrelated files or generated artifacts are included.
- [ ] Run the full UI test target if available and record any environment-only limitations.
- [ ] Commit with `docs: document configurable pomodoro long breaks`.

## Self-review

- Spec coverage: product rules, default 4 rounds, 2/3/4 options, short-break eye guidance, long-break duration, reset behavior, UI feedback, and tests are covered by Tasks 1-5.
- Placeholder scan: no TODO/TBD or unspecified implementation steps are required.
- Type consistency: `RhythmConfiguration` and `RhythmBreakKind` are extended in Task 2 before Task 3 consumes them; UI setter names remain existing AppState conventions.
