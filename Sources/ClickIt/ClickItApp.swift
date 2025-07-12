import SwiftUI

@main
struct ClickItApp: App {
    @StateObject private var permissionManager = PermissionManager.shared
    @StateObject private var hotkeyManager = HotkeyManager.shared
    
    init() {
        // Force app to appear in foreground when launched from command line
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
        
        // Initialize hotkey manager
        Task { @MainActor in
            HotkeyManager.shared.initialize()
        }
        
        // Register app termination handler for cleanup
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Cleanup visual feedback overlay when app terminates
            Task { @MainActor in
                VisualFeedbackOverlay.shared.cleanup()
                HotkeyManager.shared.cleanup()
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(permissionManager)
                .environmentObject(hotkeyManager)
                .onAppear {
                    // Additional window activation
                    if let window = NSApp.windows.first {
                        window.makeKeyAndOrderFront(nil)
                        window.orderFrontRegardless()
                    }
                }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 500, height: 800)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .help) {
                Button("Permission Setup Guide") {
                    // Open permission setup guide
                    if let url = URL(string: "https://github.com/jsonify/clickit/wiki/Permission-Setup") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }
}
