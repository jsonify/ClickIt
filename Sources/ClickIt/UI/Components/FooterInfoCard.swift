// swiftlint:disable file_header

import SwiftUI

struct FooterInfoCard: View {
    var body: some View {
        VStack(spacing: 8) {
            // Hotkey instruction
            HStack(spacing: 8) {
                Image(systemName: "keyboard")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Text("Shift+F1 to stop")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("•")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("v\(AppConstants.appVersion)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

struct FooterInfoCard_Previews: PreviewProvider {
    static var previews: some View {
        FooterInfoCard()
            .frame(width: 400)
            .padding()
    }
}
