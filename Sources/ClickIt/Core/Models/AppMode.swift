// swiftlint:disable file_header
import Foundation

/// The active UI mode for the ClickIt app.
enum AppMode: String, CaseIterable {
    case pro
    case lite
}

/// Reads and writes the persisted `AppMode` from `UserDefaults`.
enum AppModeManager {

    private static let key = "appMode"

    /// The currently persisted mode. Defaults to `.lite` if no value has been saved.
    static var current: AppMode {
        get {
            guard let raw = UserDefaults.standard.string(forKey: key),
                  let mode = AppMode(rawValue: raw) else {
                return .lite
            }
            return mode
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: key)
        }
    }
}
