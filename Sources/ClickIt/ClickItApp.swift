// swiftlint:disable file_header
import SwiftUI
import ClickItLiteUI

@main
struct ClickItApp: App {
    @AppStorage("appMode") private var appModeRawValue: String = AppMode.lite.rawValue

    @StateObject private var permissionManager = PermissionManager.shared
    @StateObject private var hotkeyManager = HotkeyManager.shared
    @StateObject private var viewModel = ClickItViewModel()

    private var currentMode: AppMode {
        AppMode(rawValue: appModeRawValue) ?? .lite
    }

    init() {
        // All initialization moved to onAppear to avoid concurrency issues during App init
        print("ClickItApp: Initialized App structure")
    }

    var body: some Scene {
        WindowGroup(id: "main-window") {
            MainWindowContent(
                permissionManager: permissionManager,
                hotkeyManager: hotkeyManager,
                viewModel: viewModel
            )
            .onAppear {
                initializeApp()
            }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 500, height: 900)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .help) {
                Button("Permission Setup Guide") {
                    // Open permission setup guide
                    // swiftlint:disable:next custom_rules
                    if let url = URL(string: "https://github.com/jsonify/clickit/wiki/Permission-Setup") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
            CommandMenu("View") {
                SwitchModeCommand()
            }
        }

        // Separate window for click test - can be moved independently (Pro mode only)
        WindowGroup(id: "click-test-window") {
            ClickTestWindow()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 900, height: 750)
        .windowToolbarStyle(.unified)
    }

    // MARK: - Safe Initialization

    private func initializeApp() {
        print("ClickItApp: Starting safe app initialization (mode: \(currentMode.rawValue))")

        // Force app to appear in foreground when launched from command line
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        // Additional window activation
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
        }

        switch currentMode {
        case .lite:
            SimpleCursorManager.shared.activateCustomCursor()

        case .pro:
            // Initialize hotkey manager safely
            HotkeyManager.shared.initialize()

            // Start permission monitoring
            permissionManager.startPermissionMonitoring()

            // Register app termination handler for cleanup
            NotificationCenter.default.addObserver(
                forName: NSApplication.willTerminateNotification,
                object: nil,
                queue: .main
            ) { _ in
                VisualFeedbackOverlay.shared.cleanup()
                HotkeyManager.shared.cleanup()
                CursorManager.shared.forceRestoreNormalCursor()
            }
        }

        print("ClickItApp: Safe app initialization completed")
    }
}

// MARK: - Main Window Content

/// Root content of the main window. Swaps content in-place when the mode changes
/// and resizes the window to fit the new mode — no second window is ever opened.
private struct MainWindowContent: View {
    @AppStorage("appMode") private var appModeRawValue: String = AppMode.lite.rawValue

    let permissionManager: PermissionManager
    let hotkeyManager: HotkeyManager
    let viewModel: ClickItViewModel

    private var currentMode: AppMode {
        AppMode(rawValue: appModeRawValue) ?? .lite
    }

    var body: some View {
        Group {
            switch currentMode {
            case .lite:
                SimplifiedMainView()
            case .pro:
                if permissionManager.allPermissionsGranted {
                    ContentView()
                        .environmentObject(permissionManager)
                        .environmentObject(hotkeyManager)
                        .environmentObject(viewModel)
                } else {
                    PermissionsGateView()
                        .environmentObject(permissionManager)
                }
            }
        }
        // When the mode changes, resize the existing window to match the new mode.
        .onChange(of: appModeRawValue) { _ in
            let size: CGSize = currentMode == .lite
                ? CGSize(width: 400, height: 600)
                : CGSize(width: 500, height: 900)
            NSApp.mainWindow?.setContentSize(size)
            NSApp.mainWindow?.center()
        }
    }
}

// MARK: - View Menu Commands

/// Menu item that switches between Pro and Lite modes.
/// Only persists the new mode — MainWindowContent reacts and resizes in place.
private struct SwitchModeCommand: View {
    @AppStorage("appMode") private var appModeRawValue: String = AppMode.lite.rawValue

    private var currentMode: AppMode {
        AppMode(rawValue: appModeRawValue) ?? .lite
    }

    var body: some View {
        Button(currentMode == .pro ? "Switch to Lite" : "Switch to Pro") {
            let newMode: AppMode = currentMode == .pro ? .lite : .pro
            AppModeManager.current = newMode
        }
    }
}
