# ClickIt — Tech Stack

## Language
- **Swift 5.9+**

## UI Framework
- **SwiftUI** — Native macOS UI, follows Apple HIG

## Build System
- **Swift Package Manager (SPM)** — primary build tool
- **Xcode** — IDE and secondary build path
- **Unified build scripts** — `build_app_unified.sh`, `run_clickit_unified.sh`

## Platform
- **macOS 15.0+ (Sequoia)** minimum deployment target
- **Apple Silicon (arm64)** — sole supported architecture

## Build Notes
- Ad-hoc signing required for debug builds on macOS 26 (no developer cert needed): `codesign --sign - --force --deep <app.bundle>`
- Run tests via Xcode toolchain (no `sudo xcode-select` needed): `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer .../XcodeDefault.xctoolchain/usr/bin/swift test --arch arm64`

## Products
- **ClickIt Pro** — full-featured, `Sources/ClickIt/` (excluding `Lite/`)
- **ClickIt Lite** — simplified primary product, `Sources/ClickIt/Lite/`

## CI/CD
- **GitHub Actions** — CI (build & test), release workflow
- **Fastlane** — build automation and release tooling
- **Release Please** — automated versioning and changelog via conventional commits

## Dependencies
- **None** — zero external Swift package dependencies

## Testing
- **Swift Testing / XCTest** — `swift test`, tests in `Tests/`
