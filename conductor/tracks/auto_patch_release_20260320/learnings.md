# Track Learnings: auto_patch_release_20260320

Patterns, gotchas, and context discovered during implementation.

## Codebase Patterns (Inherited)

- CI/CD separation: `ci.yml` = PR/push pipeline (build+test); `cicd.yml` = tag-only release pipeline (`v*` → production, `beta*` → beta) — never mix the two concerns
- SPM cache key: `${{ runner.os }}-spm-${{ hashFiles('Package.resolved', 'Package.swift') }}` with `restore-keys: ${{ runner.os }}-spm-`
- Lint/grep-only CI jobs should use `ubuntu-latest`, not `macos-15`
- Shell script version override pattern: `VERSION="${RELEASE_VERSION:-$(get_version_from_plist)}"` — env var takes priority, falls back to Info.plist

---

<!-- Learnings from implementation will be appended below -->
