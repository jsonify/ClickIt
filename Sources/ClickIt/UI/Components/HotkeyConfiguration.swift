//
//  HotkeyConfiguration.swift
//  ClickIt
//
//  Created by ClickIt on 2025-08-06.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import SwiftUI

/// Hotkey configuration component for emergency stop settings
struct HotkeyConfigurationPanel: View {
    @EnvironmentObject private var viewModel: ClickItViewModel
    @ObservedObject private var hotkeyManager = HotkeyManager.shared
    
    @State private var isExpanded = true
    
    var body: some View {
        DisclosureGroup("Emergency Stop Hotkey", isExpanded: $isExpanded) {
            VStack(spacing: 12) {
                // Enable/Disable toggle
                HStack {
                    Toggle("Enable Emergency Stop", isOn: Binding(
                        get: { viewModel.emergencyStopEnabled },
                        set: { viewModel.toggleEmergencyStop($0) }
                    ))
                    .toggleStyle(.switch)
                    
                    Spacer()
                    
                    if hotkeyManager.emergencyStopActivated {
                        Label("ACTIVE", systemImage: "stop.circle.fill")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                if viewModel.emergencyStopEnabled {
                    // Current hotkey display
                    HStack {
                        Text("Hotkey:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("ESC (Default)")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                    }
                    
                    // Status display
                    HStack {
                        Image(systemName: "keyboard")
                            .foregroundColor(.blue)
                            .font(.system(size: 14))
                        
                        Text("Press ESC to immediately stop all automation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    
                    // Instructions
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                                .font(.system(size: 12))
                            
                            Text("Emergency Stop Instructions:")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        Text("• Press the selected key to immediately stop all automation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("• Works even when ClickIt is in the background")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("• Use this if automation gets stuck or misbehaves")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.top, 8)
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Preview

struct HotkeyConfigurationPanel_Previews: PreviewProvider {
    static var previews: some View {
        HotkeyConfigurationPanel()
            .environmentObject(ClickItViewModel())
            .frame(width: 400)
            .padding()
    }
}