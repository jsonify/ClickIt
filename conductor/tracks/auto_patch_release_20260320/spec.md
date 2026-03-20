# Spec: Auto Patch Release on Main Merge

## Overview
Automate the patch version bump and release that is currently run manually
with `fastlane bump_and_release bump:patch`. A new GitHub Actions workflow
fires on every push to `main`, determines the next patch version, updates
`Info.plist`, commits the change with `[skip ci]`, pushes the tag, and
lets the existing `cicd.yml` pipeline handle the full build + release.

## Functional Requirements
1. New workflow (`auto-release.yml`) triggers on `push` to `main` only
   (not PRs, not other branches)
2. Reads the current version from the highest semantic `v*` git tag;
   defaults to `v0.0.0` if no tags exist
3. Computes the next patch version (e.g., `1.2.3` → `1.2.4`)
4. Updates `Info.plist`: both `CFBundleShortVersionString` and
   `CFBundleVersion` fields
5. Commits the `Info.plist` change using the `github-actions[bot]`
   identity with a `[skip ci]` message to prevent recursive triggering
6. Pushes the commit to `main`, then creates and pushes a `v<new_version>`
   tag — which triggers the existing `cicd.yml` release pipeline
7. Idempotent: if the computed tag already exists, logs a message and exits
   successfully without creating a duplicate
8. `README.md` Production Release section is updated to document the new
   automated flow, replacing the outdated manual Fastlane instructions

## Non-Functional Requirements
- Implemented entirely in GitHub Actions YAML (no Fastlane dependency)
- Requires `contents: write` permission
- Must not trigger itself recursively (enforced via `[skip ci]`)

## Acceptance Criteria
- [ ] Merging a feature branch to `main` automatically produces a new
      patch-version tag (e.g., `v1.2.4`)
- [ ] `Info.plist` is updated and committed before the tag is created
- [ ] `cicd.yml` fires from the new tag and completes a production release
- [ ] Workflow defaults to `v0.0.1` when no prior `v*` tags exist
- [ ] Duplicate tag scenario exits gracefully without error
- [ ] README.md clearly describes the new auto-release behavior

## Out of Scope
- Major / minor version bumps (remain manual)
- Beta releases (remain manually triggered)
- Changes to `ci.yml`, `cicd.yml`, or `fastlane/Fastfile`
