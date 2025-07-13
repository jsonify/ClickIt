
//
//  TargetingSettings.swift
//  ClickIt
//
//  Created by Jefry on 12/07/25.
//

import SwiftUI

struct TargetingSettings: View {
    @ObservedObject
    var viewModel: ClickItViewModel

    var body: some View {
        VStack(spacing: 20) {
            SettingCard(
                title: "Click Precision",
                description: "Configure click accuracy and coordinate handling"
            ) {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "scope")
                            .foregroundColor(.blue)
                        Text("High Precision Mode")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text("Active")
                            .font(.caption)
                            .foregroundColor(.green)
                    }

                    Text("ClickIt uses sub-pixel precision for accurate click placement")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            SettingCard(
                title: "Application Targeting",
                description: "Configure which application should receive the click events"
            ) {
                VStack(spacing: 12) {
                    HStack {
                        Text("Target Mode:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text("Active Application")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text("Clicks will be sent to the currently active application. "
                        + "Advanced targeting options will be available in future updates.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            SettingCard(
                title: "Coordinate System",
                description: "Display coordinate system information"
            ) {
                VStack(spacing: 12) {
                    HStack {
                        Text("Screen Resolution:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        if let screen = NSScreen.main {
                            Text("\(Int(screen.frame.width)) × \(Int(screen.frame.height))")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        Text("Coordinate Origin:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text("Bottom-Left (0, 0)")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    Text("ClickIt uses macOS native coordinate system with origin at bottom-left")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
