// swiftlint:disable file_header
import SwiftUI

@main
struct ClickItApp: App {
    @StateObject private var permissionManager = PermissionManager.shared
    @StateObject private var hotkeyManager = HotkeyManager.shared
    @StateObject private var viewModel = ClickItViewModel()
    
    init() {
        // All initialization moved to onAppear to avoid concurrency issues during App init
        print("ClickItApp: Initialized App structure")
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
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
            .onAppear {
                // Initialize app safely on MainActor
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
        }
    }
    
    // MARK: - Safe Initialization
    
    private func initializeApp() {
        print("ClickItApp: Starting safe app initialization")
        
        // Force app to appear in foreground when launched from command line
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
        // Additional window activation
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
        }
        
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
            // Cleanup visual feedback overlay when app terminates
            VisualFeedbackOverlay.shared.cleanup()
            HotkeyManager.shared.cleanup()
            // Restore cursor to normal
            CursorManager.shared.forceRestoreNormalCursor()
        }
        
        print("ClickItApp: Safe app initialization completed")
    }
}
