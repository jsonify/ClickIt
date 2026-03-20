# Spec: ClickIt Lite Stabilization & Intel Removal

## Problem
ClickIt currently targets both Intel (x86_64) and Apple Silicon (arm64), creating
universal binaries. Intel support is no longer needed and adds build complexity.
Additionally, ClickIt Lite is the primary product going forward but has not been
formally audited for quality, coverage, or rough edges since the Pro/Lite split.

## Goals
1. Cleanly remove Intel/universal binary support from build scripts, CI, and docs
2. Audit ClickIt Lite for correctness and UX polish
3. Establish a healthy test baseline for the Lite path

## Out of Scope
- New features
- ClickIt Pro improvements
- App Store distribution

## Success Criteria
- `build_app_unified.sh` and CI only target arm64
- No remaining x86_64 or "universal" references in active build/CI config
- README accurately reflects Apple Silicon-only support
- ClickIt Lite builds, launches, and clicks correctly on Apple Silicon
- `swift test` passes with no regressions
- Known Lite UX issues documented or resolved

## Affected Files
- `build_app_unified.sh` — remove x86_64 arch detection and lipo universal step
- `build_app.sh` — same
- `.github/workflows/cicd.yml` — remove Intel arch from CI matrix
- `README.md` — update system requirements and build docs
- `conductor/tech-stack.md` — already updated (Apple Silicon only)
- `Sources/ClickIt/Lite/` — audit all files
- `Tests/` — ensure Lite-relevant paths are covered
