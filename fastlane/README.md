fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Mac

### mac build_debug

```sh
[bundle exec] fastlane mac build_debug
```

Build ClickIt app (Debug)

### mac build_release

```sh
[bundle exec] fastlane mac build_release
```

Build ClickIt app (Release)

### mac launch

```sh
[bundle exec] fastlane mac launch
```

Build and run ClickIt app

### mac clean

```sh
[bundle exec] fastlane mac clean
```

Clean build artifacts

### mac verify_signing

```sh
[bundle exec] fastlane mac verify_signing
```

Verify code signing status

### mac info

```sh
[bundle exec] fastlane mac info
```

Show app bundle information

### mac release

```sh
[bundle exec] fastlane mac release
```

Full release workflow

### mac dev

```sh
[bundle exec] fastlane mac dev
```

Development workflow

### mac local

```sh
[bundle exec] fastlane mac local
```

Build ClickIt for local development and testing

### mac beta

```sh
[bundle exec] fastlane mac beta
```

Create beta release on staging branch with beta-* tag

### mac prod

```sh
[bundle exec] fastlane mac prod
```

Create production release on main branch with v* tag

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
