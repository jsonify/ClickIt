import SwiftUI

/// Simple update button component for development builds
/// Part of Phase 1 MVP implementation for manual update checking
struct DeveloperUpdateButton: View {
    @ObservedObject var updaterManager: UpdaterManager
    
    var body: some View {
        VStack(spacing: 8) {
            Button("Check for Updates") {
                updaterManager.checkForUpdates()
            }
            .disabled(updaterManager.isCheckingForUpdates)
            .buttonStyle(.bordered)
            .controlSize(.regular)
            
            if updaterManager.isUpdateAvailable {
                Button("Install Update") {
                    updaterManager.installUpdate()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
            
            // Show status information
            if updaterManager.isCheckingForUpdates {
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.6)
                    Text("Checking...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if let error = updaterManager.updateError {
                Text("Error: \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            } else if updaterManager.isUpdateAvailable {
                Text("Update available: \(updaterManager.formatVersionInfo())")
                    .font(.caption)
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
            } else if updaterManager.lastUpdateCheck != nil {
                Text("No updates available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    DeveloperUpdateButton(updaterManager: UpdaterManager())
}