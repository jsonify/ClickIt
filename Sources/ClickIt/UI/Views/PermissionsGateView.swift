import SwiftUI

struct PermissionsGateView: View {
    @StateObject private var permissionManager = PermissionManager.shared
    @State private var showingDetailedInstructions = false
    @State private var selectedPermission: PermissionType?
    @State private var isRequestingPermissions = false
    @State private var isRefreshingPermissions = false
    @State private var refreshErrorMessage: String?
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // App Header
            VStack(spacing: 16) {
                Image(systemName: "hand.point.up.braille")
                    .font(.system(size: 64))
                    .foregroundColor(.accentColor)
                
                Text("ClickIt")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Precision Auto-Clicker for macOS")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            // Permission Requirements
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Setup Required")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("ClickIt needs these permissions to function properly:")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Permission List
                VStack(spacing: 12) {
                    PermissionGateRow(
                        permission: .accessibility,
                        isGranted: permissionManager.accessibilityPermissionGranted,
                        onOpenSettings: { openSystemSettings(for: .accessibility) }
                    )
                    
                    PermissionGateRow(
                        permission: .screenRecording,
                        isGranted: permissionManager.screenRecordingPermissionGranted,
                        onOpenSettings: { openSystemSettings(for: .screenRecording) }
                    )
                }
                .frame(maxWidth: 400)
            }
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 16) {
                if permissionManager.allPermissionsGranted {
                    Button("Continue to ClickIt") {
                        // This will be handled by the parent view when allPermissionsGranted becomes true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(true) // This button is just for show, transition happens automatically
                } else {
                    VStack(spacing: 12) {
                        Button("Grant All Permissions") {
                            requestAllPermissions()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(isRequestingPermissions)
                        
                        Button(action: { refreshPermissionStatus() }) {
                            HStack(spacing: 8) {
                                if isRefreshingPermissions {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                                Text(isRefreshingPermissions ? "Resetting..." : "Refresh Status")
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                        .disabled(isRefreshingPermissions)
                        
                        Button("Need Help?") {
                            showingDetailedInstructions = true
                        }
                        .buttonStyle(.borderless)
                        .controlSize(.small)
                    }
                    
                    // Error Message Display
                    if let errorMessage = refreshErrorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
            }
            
            // Status Footer
            VStack(spacing: 8) {
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(permissionManager.accessibilityPermissionGranted ? .green : .red)
                        .frame(width: 8, height: 8)
                    
                    Circle()
                        .fill(permissionManager.screenRecordingPermissionGranted ? .green : .red)
                        .frame(width: 8, height: 8)
                    
                    Text("Permission Status")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(40)
        .frame(maxWidth: 600, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            permissionManager.startPermissionMonitoring()
            permissionManager.updatePermissionStatus()
        }
        .onDisappear {
            permissionManager.stopPermissionMonitoring()
        }
        .sheet(isPresented: $showingDetailedInstructions) {
            PermissionInstructionsView(permission: selectedPermission)
        }
        .overlay(
            Group {
                if isRequestingPermissions {
                    ZStack {
                        Color.black.opacity(0.3)
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            
                            Text("Requesting permissions...")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        .padding(32)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(12)
                        .shadow(radius: 8)
                    }
                    .ignoresSafeArea()
                }
            }
        )
    }
    
    // MARK: - Helper Properties
    
    private var statusText: String {
        let granted = [
            permissionManager.accessibilityPermissionGranted,
            permissionManager.screenRecordingPermissionGranted
        ].filter { $0 }.count
        
        if granted == 2 {
            return "All permissions granted - ready to continue"
        } else if granted == 1 {
            return "1 of 2 permissions granted"
        } else {
            return "No permissions granted yet"
        }
    }
    
    // MARK: - Actions
    
    private func requestAllPermissions() {
        isRequestingPermissions = true
        Task {
            _ = await permissionManager.requestAllPermissions()
            await MainActor.run {
                isRequestingPermissions = false
            }
        }
    }
    
    private func refreshPermissionStatus() {
        isRefreshingPermissions = true
        refreshErrorMessage = nil
        
        Task {
            let success = await permissionManager.refreshWithReset()
            
            await MainActor.run {
                isRefreshingPermissions = false
                if !success {
                    refreshErrorMessage = "Could not reset permissions. Try manually removing ClickIt from Accessibility settings."
                    
                    // Auto-clear error after 5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        refreshErrorMessage = nil
                    }
                }
            }
        }
    }
    
    private func openSystemSettings(for permission: PermissionType) {
        permissionManager.openSystemSettings(for: permission)
    }
}

// MARK: - Permission Gate Row Component

struct PermissionGateRow: View {
    let permission: PermissionType
    let isGranted: Bool
    let onOpenSettings: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Permission Icon
            Image(systemName: permission.systemIcon)
                .font(.title2)
                .foregroundColor(isGranted ? .green : .orange)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(isGranted ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                )
            
            // Permission Info
            VStack(alignment: .leading, spacing: 4) {
                Text(permission.rawValue)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(permission.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            // Status & Action
            HStack(spacing: 12) {
                // Status Indicator
                Image(systemName: isGranted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundColor(isGranted ? .green : .orange)
                    .font(.title3)
                
                // Action Button
                if !isGranted {
                    Button("Grant") {
                        onOpenSettings()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isGranted ? Color.green.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct PermissionsGateView_Previews: PreviewProvider {
    static var previews: some View {
        PermissionsGateView()
    }
}
