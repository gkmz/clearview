# ClearView 0.1 Release Gap Checklist

> Scope: This checklist is strictly based on currently implemented functionality and targets a stable open-source 0.1 release.

## Release Gates

### P0 — Must Have (0.1 blocker)
1. **Documentation consistency**
   - README, product plan, and release checklist use aligned terminology and feature boundaries.
2. **Scope freeze**
   - 0.1 explicitly covers only implemented capabilities.
3. **Runnable onboarding**
   - New users can run the app with README alone.
4. **Public limitations**
   - Non-implemented features are clearly marked as roadmap items.

### P1 — Should Have (strongly recommended)
1. **Manual QA checklist**
   - start/pause/resume flow
   - reminder phase transitions
   - snooze and complete actions
   - blue light filter apply/recover
   - shortcut conflict behavior
   - persistence after restart
2. **Compatibility notes**
   - macOS versions tested
   - Apple Silicon / Intel behavior notes
   - single vs multi-display notes
3. **Version notes template**
   - release notes format for fixes, known issues, next steps

### P2 — Deferred (0.2+)
1. Usage analytics dashboard
2. Context-aware automatic pause strategies
3. Cloud sync and multi-device coordination

## Clarification: Pause vs “Silent Mode”
- **Implemented now**: manual pause/resume via menu (`暂不打扰 / 继续提醒`).
- **Not implemented**: automatic context-aware silence (e.g., meeting/fullscreen detection).

## Definition of Done for 0.1
1. Required docs exist and are navigable from README.
2. Documented capabilities match actual code behavior.
3. First-time user can complete one reminder loop without external guidance.
4. No roadmap item is presented as already shipped.
