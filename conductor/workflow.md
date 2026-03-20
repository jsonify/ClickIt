# Conductor Workflow

## Test Coverage
- Minimum **80% coverage** for Core layer
- Run `swift test` before marking any task complete
- Tests must pass before committing

## Commit Cadence
- Commit after **each task** (not each phase)
- Use Conventional Commits format (see `code_styleguides/swift-swiftui.md`)
- Message format: `type(scope): description`

## Task Summaries
- Use **Git Notes** to attach implementation summaries to commits
- Add note: `git notes add -m "summary of what was done and why"`

## Task Lifecycle
1. Read `spec.md` and `plan.md` for the current track
2. Pick the next unchecked task
3. Implement, write/update tests
4. Run `swift test` — all tests must pass
5. Commit with conventional commit message
6. Add git note summarizing the task
7. Mark task complete in `plan.md`
8. On phase completion: complete the manual verification task before moving on

## Manual Verification (Phase Completion)
Each phase ends with a "Conductor - User Manual Verification" task.
- Do not mark it complete automatically
- Pause and surface it to the user for sign-off
- Resume only after user confirms

## Definition of Done (Task)
- [ ] Feature/fix implemented
- [ ] Tests written or updated
- [ ] `swift test` passes
- [ ] Committed with conventional commit
- [ ] Git note attached

## Definition of Done (Track)
- [ ] All tasks complete
- [ ] All phases manually verified
- [ ] No regressions in `swift test`
- [ ] Track status updated to `complete` in `metadata.json`
- [ ] Learnings appended to `learnings.md`
