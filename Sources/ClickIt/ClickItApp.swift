// swiftlint:disable file_header
import SwiftUI

@main
struct ClickItApp: App {
    @StateObject private var permissionManager = PermissionManager.shared
    @StateObject private var hotkeyManager = HotkeyManager.shared
    @StateObject private var viewModel = ClickItViewModel()
    
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
    
    private func openSettingsWindow() {
        // Check if settings window is already open
        for window in NSApp.windows {
            if window.title == "Advanced Settings" {
                window.makeKeyAndOrderFront(nil)
                return
            }
        }
        
        // Create new settings window
        let settingsView = AdvancedSettingsWindow(viewModel: viewModel)
        let settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        settingsWindow.title = "Advanced Settings"
        settingsWindow.contentView = NSHostingView(rootView: settingsView)
        settingsWindow.center()
        settingsWindow.makeKeyAndOrderFront(nil)
        
        // Keep a reference to prevent deallocation
        settingsWindow.isReleasedWhenClosed = false
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
                // Additional window activation
                if let window = NSApp.windows.first {
                    window.makeKeyAndOrderFront(nil)
                    window.orderFrontRegardless()
                }
                
                // Start permission monitoring
                permissionManager.startPermissionMonitoring()
            }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 500, height: 800)
        .windowToolbarStyle(.unified)
        .commands {
            // Add Settings to main menu in proper location
            CommandGroup(after: .appInfo) {
                Button("Settings...") {
                    openSettingsWindow()
                }
                .keyboardShortcut(",", modifiers: .command)
                
                Divider()
            }
            
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
}
