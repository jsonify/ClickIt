import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var permissionManager: PermissionManager
    @EnvironmentObject private var hotkeyManager: HotkeyManager
    @StateObject private var clickCoordinator = ClickCoordinator.shared
    @State private var showingPermissionSetup = false
    @State private var showingWindowDetectionTest = false
    @State private var selectedClickPoint: CGPoint?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // App Icon Placeholder
                Image(systemName: "cursorarrow.click.2")
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)
                
                // App Title
                Text("ClickIt")
                    .font(.title)
                    .fontWeight(.bold)
                
                // Subtitle
                Text("Precision Auto-Clicker for macOS")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Permission Status
                VStack(spacing: 10) {
                    if permissionManager.allPermissionsGranted {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(.green)
                            Text("Ready to use")
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                        .padding(12)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    } else {
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.shield")
                                    .foregroundColor(.orange)
                                Text("Permissions Required")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                            }
                            
                            Button("Setup Permissions") {
                                showingPermissionSetup = true
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        }
                        .padding(12)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Compact permission status
                    CompactPermissionStatus()
                }
                
                // Hotkey Status
                if permissionManager.allPermissionsGranted {
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: hotkeyManager.isRegistered ? "keyboard.fill" : "keyboard")
                                .foregroundColor(hotkeyManager.isRegistered ? .blue : .orange)
                            Text(hotkeyManager.isRegistered ? "ESC Hotkey Active" : "Hotkey Registration Failed")
                                .font(.caption)
                                .foregroundColor(hotkeyManager.isRegistered ? .blue : .orange)
                        }
                        
                        if let error = hotkeyManager.lastError {
                            Text("Error: \(error)")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(8)
                    .background(hotkeyManager.isRegistered ? Color.blue.opacity(0.1) : Color.orange.opacity(0.1))
                    .cornerRadius(6)
                }
                
                // Main Application Interface (only show when permissions are granted)
                if permissionManager.allPermissionsGranted {
                    // Click Point Selection
                    ClickPointSelector { point in
                        selectedClickPoint = point
                    }
                    
                    // Configuration Panel
                    ConfigurationPanel(selectedClickPoint: selectedClickPoint)
                        .environmentObject(clickCoordinator)
                    
                    // Development Tools (collapsible section)
                    DisclosureGroup("Development Tools") {
                        VStack(spacing: 8) {
                            Button("Test Window Detection") {
                                showingWindowDetectionTest = true
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.regular)
                            
                            if let point = selectedClickPoint {
                                Button("Test Click at Selected Point") {
                                    testClickAtPoint(point)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.regular)
                            }
                            
                            Button("Test ESC Hotkey") {
                                testHotkeySystem()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.regular)
                        }
                        .padding(8)
                    }
                    .padding(12)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Version Info
                VStack(spacing: 4) {
                    Text("Version \(AppConstants.appVersion)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Build \(AppConstants.buildNumber)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("Requires \(AppConstants.minimumOSVersion) or later")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .frame(width: 500, height: 800)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            permissionManager.updatePermissionStatus()
            // Start monitoring for permission changes
            permissionManager.startPermissionMonitoring()
        }
        .sheet(isPresented: $showingPermissionSetup) {
            PermissionRequestView()
        }
        .sheet(isPresented: $showingWindowDetectionTest) {
            WindowDetectionTestView()
        }
    }
    
    private func testClickAtPoint(_ point: CGPoint) {
        Task {
            let configuration = ClickConfiguration(
                type: .left,
                location: point,
                targetPID: nil,
                delayBetweenDownUp: 0.01
            )
            
            let result = await ClickCoordinator.shared.performSingleClick(configuration: configuration)
            
            print("Click test result: \(result)")
        }
    }
    
    private func testHotkeySystem() {
        if hotkeyManager.isRegistered {
            print("ESC hotkey is registered. Press ESC to test.")
            
            // Start a test automation to demonstrate ESC key stopping it
            if let point = selectedClickPoint {
                let config = AutomationConfiguration(
                    location: point,
                    clickInterval: 2.0,
                    maxClicks: 10,
                    showVisualFeedback: true
                )
                clickCoordinator.startAutomation(with: config)
                print("Started test automation - press ESC to stop it")
            } else {
                print("Please select a click point first to test ESC hotkey")
            }
        } else {
            print("ESC hotkey is not registered")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PermissionManager.shared)
        .environmentObject(HotkeyManager.shared)
}