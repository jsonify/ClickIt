//
//  AutomationSettings.swift
//  ClickIt
//
//  Created by Jefry on 12 / 07 / 25.
//

import SwiftUI

struct AutomationSettings: View {
    @ObservedObject
    var viewModel: ClickItViewModel

    var body: some View {
        VStack(spacing: 20) {
            SettingCard(
                title: "Error Handling",
                description: "Configure how ClickIt responds to errors during automation"
            ) {
                VStack(spacing: 12) {
                    Toggle("Stop on Error", isOn: $viewModel.stopOnError)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(viewModel.stopOnError
                        ? "Automation will stop if any errors occur"
                        : "Automation will continue even if errors occur")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 16)
                }
            }

            SettingCard(
                title: "Emergency Stop Configuration",
                description: "Configure global emergency stop hotkey for instant automation control"
            ) {
                VStack(spacing: 16) {
                    // Emergency Stop Toggle
                    HStack {
                        Toggle("Enable Emergency Stop", isOn: $viewModel.emergencyStopEnabled)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .onChange(of: viewModel.emergencyStopEnabled) { oldValue, newValue in
                                viewModel.toggleEmergencyStop(newValue)
                            }
                    }
                    
                    if viewModel.emergencyStopEnabled {
                        Divider()
                        
                        // Emergency Stop Key Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Emergency Stop Key")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            // Current Selection Display
                            HStack {
                                Image(systemName: emergencyStopIcon(for: viewModel.selectedEmergencyStopKey))
                                    .foregroundColor(.red)
                                    .font(.title2)
                                Text(viewModel.selectedEmergencyStopKey.description)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Text("EMERGENCY STOP")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(4)
                            }
                            
                            // Key Selection Menu
                            Menu {
                                ForEach(viewModel.getAvailableEmergencyStopKeys(), id: \.keyCode) { config in
                                    Button(action: {
                                        viewModel.setEmergencyStopKey(config)
                                    }) {
                                        HStack {
                                            Image(systemName: emergencyStopIcon(for: config))
                                            Text(config.description)
                                            if config.keyCode == viewModel.selectedEmergencyStopKey.keyCode &&
                                               config.modifiers == viewModel.selectedEmergencyStopKey.modifiers {
                                                Spacer()
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Text("Change Emergency Stop Key")
                                        .font(.caption)
                                    Image(systemName: "chevron.down")
                                        .font(.caption2)
                                }
                                .foregroundColor(.blue)
                            }
                            .buttonStyle(.borderless)
                            
                            // Response Time Display
                            if HotkeyManager.shared.emergencyStopActivated {
                                HStack {
                                    Image(systemName: "bolt.fill")
                                        .foregroundColor(.yellow)
                                        .font(.caption)
                                    Text("EMERGENCY STOP ACTIVATED")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.red)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(6)
                            }
                        }
                        
                        Divider()
                        
                        // Help Text
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Emergency Stop Usage:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            Text("• Press \(viewModel.selectedEmergencyStopKey.description) at any time to instantly stop automation")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("• Works globally, even when ClickIt is not the active application")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("• Response time target: <50ms for immediate safety")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func emergencyStopIcon(for config: HotkeyConfiguration) -> String {
        switch config.keyCode {
        case 53:  // ESC
            return "exclamationmark.octagon.fill"
        case 51:  // DELETE
            return "delete.backward.fill"
        case 122: // F1
            return "f.square.fill"
        case 49:  // Space
            return "space"
        case 47:  // Period (for Cmd+Period)
            return "command.square.fill"
        default:
            return "keyboard.fill"
        }
    }
}
