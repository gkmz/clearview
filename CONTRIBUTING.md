# Contributing to ClearView

Thanks for your interest in contributing to ClearView.

## Ground Rules
- Keep changes focused and minimal.
- Do not mix refactor-only changes with feature changes in one PR.
- Update docs when behavior changes.
- Keep product scope aligned with the current milestone.

## Development Setup
1. Use macOS 13+.
2. Open `Package.swift` in Xcode.
3. Run target `ClearViewApp`.

## Branch & Commit Guidelines
- Branch naming (recommended):
  - `feat/<short-description>`
  - `fix/<short-description>`
  - `docs/<short-description>`
- Commit style (recommended):
  - `feat: ...`
  - `fix: ...`
  - `docs: ...`
  - `refactor: ...`

## Pull Request Checklist
- [ ] Scope is clear and limited.
- [ ] Behavior is tested manually on target flow.
- [ ] Related docs are updated (`README.md`, `docs/*` if needed).
- [ ] No roadmap-only capability is presented as shipped.

## What to Include in a PR Description
- Problem statement
- What changed
- How it was tested
- Any known limitations

## Reporting Bugs
Please include:
- macOS version
- chip architecture (Apple Silicon / Intel)
- display setup (single / multi-monitor)
- reproduction steps
- expected vs actual behavior

## Feature Requests
Please include:
- user scenario
- why current behavior is insufficient
- expected product impact
