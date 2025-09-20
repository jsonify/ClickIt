//
//  AdvancedTechnicalSettings.swift
//  ClickIt
//
//  Created by Jefry on 12 / 07 / 25.
//

import SwiftUI

struct AdvancedTechnicalSettings: View {
    @ObservedObject
    var viewModel: ClickItViewModel

    var body: some View {
        VStack(spacing: 20) {
            SettingCard(
                title: "Performance Information",
                description: "System performance and technical details"
            ) {
                VStack(spacing: 12) {
                    HStack {
                        Text("Click Timing Accuracy:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text("< 10ms")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.green)
                    }

                    HStack {
                        Text("Memory Usage:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text("< 50MB")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.green)
                    }

                    HStack {
                        Text("CPU Usage (Idle):")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text("< 5%")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.green)
                    }

                    Text("ClickIt is optimized for high performance with minimal system impact")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            SettingCard(
                title: "System Information",
                description: "macOS version and compatibility details"
            ) {
                VStack(spacing: 12) {
                    HStack {
                        Text("Required macOS:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text("\(AppConstants.minimumOSVersion)+")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Architecture:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text("Universal Binary")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("App Version:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text("v\(AppConstants.appVersion)")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    Text("Compatible with Intel x64 and Apple Silicon Macs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            SettingCard(
                title: "Configuration Management",
                description: "Backup, restore, and manage your settings"
            ) {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Button(action: {
                            viewModel.resetConfiguration()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise")
                                Text("Reset to Defaults")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)

                        Button(action: {
                            viewModel.exportSettings()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export Settings")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                    }
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            viewModel.importSettings()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.down")
                                Text("Import Settings")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                        
                        Spacer()
                            .frame(maxWidth: .infinity)
                    }

                    VStack(spacing: 4) {
                        Text("Export saves all your current settings to a JSON file")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Import restores settings from a previously exported file")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}
