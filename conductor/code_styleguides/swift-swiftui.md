# Swift & SwiftUI Styleguide

## Naming
- Types: `UpperCamelCase` — `ClickEngine`, `SimpleViewModel`
- Functions/properties: `lowerCamelCase` — `startClicking()`, `isRunning`
- Constants: `lowerCamelCase` — `maxCPS`, `defaultInterval`
- Booleans: prefix with `is`, `has`, `can`, `should` — `isActive`, `canStart`

## File Organization
- One type per file; filename matches type name
- Group by feature, not by type: `Core/Click/`, `Core/Timer/`, `UI/Components/`
- Place `// MARK: -` sections in this order: Properties, Init, Body/View, Methods, Private

## SwiftUI Views
- Keep `body` under ~50 lines; extract subviews aggressively
- Prefer `private` for subview structs defined in the same file
- Use `@StateObject` for view-owned ViewModels, `@ObservedObject` for injected ones
- Avoid business logic in views — delegate to ViewModel or Core layer
- Follow Apple HIG: use system colors, fonts (`Font.body`, `.caption`), and controls

## Swift Conventions
- Prefer `let` over `var` everywhere possible
- Use `guard` for early returns over nested `if`
- Avoid force unwrap (`!`); use `guard let` or `if let`
- Mark all single-use helpers `private`
- Use `async/await` over callbacks for async work
- Prefer value types (`struct`) over reference types (`class`) unless shared mutable state is needed

## Error Handling
- Surface errors with direct, actionable messages (see product-guidelines.md)
- Prefer `Result<T, Error>` or `throws` over optional returns for fallible operations
- Never silently swallow errors — at minimum `os_log` them

## Comments
- No redundant comments (don't restate what the code says)
- Comment *why*, not *what*
- Use `// MARK: -` to organize sections, not `//---` or other dividers

## Testing
- Target >80% coverage for Core layer logic
- Test behavior, not implementation details
- Name tests: `test_<method>_<condition>_<expectedResult>()`

## Commit Messages
Follow Conventional Commits:
- `feat:` new feature
- `fix:` bug fix
- `refactor:` code change with no behavior change
- `test:` adding/updating tests
- `chore:` tooling, CI, build changes
