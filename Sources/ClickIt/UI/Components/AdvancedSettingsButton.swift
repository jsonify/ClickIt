// swiftlint:disable file_header
import SwiftUI

struct AdvancedSettingsButton: View {
    @ObservedObject var viewModel: ClickItViewModel
    @State private var showingAdvancedSettings = false
    
    var body: some View {
        Button(action: {
            showingAdvancedSettings = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "gearshape.2")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Advanced Settings")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Duration, feedback, targeting, and more")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingAdvancedSettings) {
            AdvancedSettingsWindow(viewModel: viewModel)
        }
    }
}

struct AdvancedSettingsButton_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedSettingsButton(viewModel: ClickItViewModel())
            .frame(width: 400)
            .padding()
    }
}
