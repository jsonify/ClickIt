//
//  SettingsTab.swift
//  ClickIt
//
//  Created by ClickIt on 2025-08-06.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import SwiftUI

/// Settings tab containing organized advanced options
struct SettingsTab: View {
    @EnvironmentObject private var viewModel: ClickItViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Tab header
                HStack {
                    Image(systemName: "gearshape.2")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text("Settings")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // Settings status indicator
                    Label("Configured", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                        .opacity(0.8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                VStack(spacing: 12) {
                    // Emergency stop hotkey configuration
                    HotkeyConfigurationPanel()
                    
                    // Visual and audio feedback settings  
                    VisualFeedbackSettings()
                    
                    // Advanced timing options
                    AdvancedTimingSettings()
                    
                    // Application preferences
                    ApplicationPreferences()
                }
                .padding(.horizontal, 16)
                
                // Settings footer with reset option
                SettingsFooter()
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Application Preferences Component

private struct ApplicationPreferences: View {
    @EnvironmentObject private var viewModel: ClickItViewModel
    @State private var isExpanded = false
    
    var body: some View {
        DisclosureGroup("Application Preferences", isExpanded: $isExpanded) {
            VStack(spacing: 16) {
                // Launch preferences
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "power")
                            .foregroundColor(.green)
                            .font(.system(size: 14))
                        
                        Text("Launch Options")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                    }
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("Start at Login")
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text("Available in Settings")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Visual Feedback")
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Toggle("", isOn: $viewModel.showVisualFeedback)
                                .toggleStyle(.switch)
                        }
                        
                        HStack {
                            Text("Sound Feedback")
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Toggle("", isOn: $viewModel.playSoundFeedback)
                                .toggleStyle(.switch)
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(6)
                
                // UI preferences
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "paintbrush")
                            .foregroundColor(.purple)
                            .font(.system(size: 14))
                        
                        Text("Interface")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                    }
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("App Status")
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text(viewModel.appStatus.displayText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Emergency Stop")
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text(viewModel.emergencyStopEnabled ? "Enabled" : "Disabled")
                                .font(.caption)
                                .foregroundColor(viewModel.emergencyStopEnabled ? .green : .red)
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(6)
            }
            .padding(.top, 8)
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Settings Footer Component

private struct SettingsFooter: View {
    @EnvironmentObject private var viewModel: ClickItViewModel
    @State private var showResetAlert = false
    
    var body: some View {
        VStack(spacing: 12) {
            Divider()
                .padding(.horizontal, 16)
            
            HStack {
                // Settings info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                        
                        Text("Settings Information")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("All settings are saved automatically and persist across app launches")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Reset button
                Button("Reset All Settings") {
                    showResetAlert = true
                }
                .buttonStyle(.borderless)
                .foregroundColor(.red)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .alert("Reset All Settings", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                // Reset basic settings to defaults
                viewModel.showVisualFeedback = true
                viewModel.playSoundFeedback = false
                viewModel.stopOnError = true
                viewModel.randomizeLocation = false
                viewModel.locationVariance = 0
            }
        } message: {
            Text("This will reset visible settings to their default values.")
        }
    }
}

// MARK: - Preview

struct SettingsTab_Previews: PreviewProvider {
    static var previews: some View {
        SettingsTab()
            .environmentObject(ClickItViewModel())
            .frame(width: 500, height: 600)
    }
}