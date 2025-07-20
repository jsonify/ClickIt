import SwiftUI

/// Card component that displays update notifications and controls
struct UpdateNotificationCard: View {
    @ObservedObject var updaterManager: UpdaterManager
    @State private var showingUpdateDetails = false
    
    var body: some View {
        VStack(spacing: 12) {
            if updaterManager.isCheckingForUpdates {
                checkingForUpdatesView
            } else if updaterManager.isUpdateAvailable {
                updateAvailableView
            }
        }
        .padding(16)
        .background(backgroundGradient)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .sheet(isPresented: $showingUpdateDetails) {
            UpdateDetailsView(updaterManager: updaterManager)
        }
    }
    
    @ViewBuilder
    private var checkingForUpdatesView: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Checking for Updates")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Looking for the latest version...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private var updateAvailableView: some View {
        VStack(spacing: 12) {
            // Update Header
            HStack(spacing: 12) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Update Available")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if updaterManager.updateVersion != nil {
                        Text("Version \(updaterManager.formatVersionInfo())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Update Actions
                HStack(spacing: 8) {
                    Button("Details") {
                        showingUpdateDetails = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button("Update Now") {
                        updaterManager.installUpdate()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.blue.opacity(0.05),
                Color.green.opacity(0.05)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

/// Detailed view for update information
struct UpdateDetailsView: View {
    @ObservedObject var updaterManager: UpdaterManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if updaterManager.updateVersion != nil {
                        // Version Information
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Update Information")
                                .font(.headline)
                            
                            InfoRow(label: "Current Version", value: updaterManager.currentVersion)
                            InfoRow(label: "New Version", value: updaterManager.formatVersionInfo())
                            
                            if let releaseNotesURL = updaterManager.updateReleaseNotes {
                                InfoRow(label: "Release Notes URL", value: releaseNotesURL)
                            }
                        }
                        .padding()
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(8)
                        
                        // Release Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Release Notes")
                                .font(.headline)
                            
                            if let releaseNotes = updaterManager.getReleaseNotes() {
                                Text(releaseNotes)
                                    .font(.body)
                                    .padding()
                                    .background(Color(.textBackgroundColor))
                                    .cornerRadius(8)
                            } else {
                                Text("No release notes available")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                        }
                        
                        // Update Actions
                        VStack(spacing: 12) {
                            Button("Install Update") {
                                updaterManager.installUpdate()
                                dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .frame(maxWidth: .infinity)
                            
                            HStack(spacing: 12) {
                                Button("Skip This Version") {
                                    if let version = updaterManager.updateVersion {
                                        updaterManager.skipVersion(version)
                                    }
                                    dismiss()
                                }
                                .buttonStyle(.bordered)
                                
                                Button("Remind Me Later") {
                                    dismiss()
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(.top)
                    }
                }
                .padding()
            }
            .navigationTitle("Update Available")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 500, height: 600)
    }
}

/// Helper view for displaying information rows
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    UpdateNotificationCard(updaterManager: UpdaterManager())
}