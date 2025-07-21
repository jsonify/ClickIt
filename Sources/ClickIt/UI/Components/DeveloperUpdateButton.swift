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
            } else if let result = updaterManager.lastCheckResult {
                Text(result)
                    .font(.caption)
                    .foregroundColor(updaterManager.isUpdateAvailable ? .green : 
                                   updaterManager.updateError != nil ? .red : .secondary)
                    .multilineTextAlignment(.center)
            } else if let error = updaterManager.updateError {
                Text("Error: \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
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

struct DeveloperUpdateButton_Previews: PreviewProvider {
    static var previews: some View {
        DeveloperUpdateButton(updaterManager: UpdaterManager())
    }
}