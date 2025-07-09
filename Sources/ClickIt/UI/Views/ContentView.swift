import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 24) {
            // App Icon Placeholder
            Image(systemName: "cursorarrow.click.2")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
            
            // App Title
            Text("ClickIt")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Subtitle
            Text("Precision Auto-Clicker for macOS")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Version Info
            VStack(spacing: 4) {
                Text("Version \(AppConstants.appVersion)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Build \(AppConstants.buildNumber)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // System Requirements
            Text("Requires \(AppConstants.minimumOSVersion) or later")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 300, height: 400)
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }
}

#Preview {
    ContentView()
}
