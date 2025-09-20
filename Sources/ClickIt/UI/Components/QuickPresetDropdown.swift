//
//  QuickPresetDropdown.swift
//  ClickIt
//
//  Created by ClickIt on 2025-08-06.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import SwiftUI

struct QuickPresetDropdown: View {
    @EnvironmentObject private var viewModel: ClickItViewModel
    @ObservedObject private var presetManager = PresetManager.shared
    @State private var selectedPresetName = "Default"
    
    private var presetNames: [String] {
        presetManager.availablePresets.map { $0.name }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "folder")
                    .foregroundColor(.blue)
                    .font(.system(size: 14))
                
                Text("Quick Preset")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                // Preset count
                Text("\(presetNames.count) saved")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 8) {
                // Preset picker
                Picker("Preset", selection: $selectedPresetName) {
                    Text("Current Settings").tag("Default")
                    
                    if !presetNames.isEmpty {
                        Divider()
                        ForEach(presetNames, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity)
                .onChange(of: selectedPresetName) { _, newValue in
                    if newValue != "Default" {
                        loadPreset(named: newValue)
                    }
                }
                
                // Load button
                Button(action: {
                    if selectedPresetName != "Default" {
                        loadPreset(named: selectedPresetName)
                    }
                }) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 14))
                }
                .buttonStyle(.borderless)
                .disabled(selectedPresetName == "Default" || viewModel.isRunning)
                .help("Load selected preset")
                
                // Save button
                Button(action: {
                    saveCurrentAsPreset()
                }) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 14))
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.isRunning)
                .help("Save current settings as preset")
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .onAppear {
            // Reset to current settings when view appears
            selectedPresetName = "Default"
        }
    }
    
    private func loadPreset(named name: String) {
        guard let preset = presetManager.loadPreset(name: name) else { return }
        
        // Load time components directly from preset
        viewModel.intervalHours = preset.intervalHours
        viewModel.intervalMinutes = preset.intervalMinutes
        viewModel.intervalSeconds = preset.intervalSeconds
        viewModel.intervalMilliseconds = preset.intervalMilliseconds
        
        // Load other settings
        viewModel.clickType = preset.clickType
        viewModel.durationMode = preset.durationMode
        viewModel.durationSeconds = preset.durationSeconds
        viewModel.maxClicks = preset.maxClicks
        
        if let targetPoint = preset.targetPoint {
            viewModel.targetPoint = targetPoint
        }
        
        viewModel.randomizeLocation = preset.randomizeLocation
        viewModel.locationVariance = preset.locationVariance
        viewModel.stopOnError = preset.stopOnError
        viewModel.showVisualFeedback = preset.showVisualFeedback
        viewModel.playSoundFeedback = preset.playSoundFeedback
        
        print("QuickPresetDropdown: Loaded preset '\(name)'")
    }
    
    private func saveCurrentAsPreset() {
        // Generate a default name if none provided
        let timestamp = DateFormatter.presetName.string(from: Date())
        let defaultName = "Preset \(timestamp)"
        
        // Create new preset from current settings
        let newPreset = PresetConfiguration(
            name: defaultName,
            targetPoint: viewModel.targetPoint,
            clickType: viewModel.clickType,
            intervalHours: viewModel.intervalHours,
            intervalMinutes: viewModel.intervalMinutes,
            intervalSeconds: viewModel.intervalSeconds,
            intervalMilliseconds: viewModel.intervalMilliseconds,
            durationMode: viewModel.durationMode,
            durationSeconds: viewModel.durationSeconds,
            maxClicks: viewModel.maxClicks,
            randomizeLocation: viewModel.randomizeLocation,
            locationVariance: viewModel.locationVariance,
            stopOnError: viewModel.stopOnError,
            showVisualFeedback: viewModel.showVisualFeedback,
            playSoundFeedback: viewModel.playSoundFeedback,
            selectedEmergencyStopKey: viewModel.selectedEmergencyStopKey,
            emergencyStopEnabled: viewModel.emergencyStopEnabled,
            timerMode: viewModel.timerMode,
            timerDurationMinutes: viewModel.timerDurationMinutes,
            timerDurationSeconds: viewModel.timerDurationSeconds
        )
        
        presetManager.savePreset(newPreset)
        selectedPresetName = defaultName
        
        print("QuickPresetDropdown: Saved current settings as '\(defaultName)'")
    }
}

// MARK: - DateFormatter Extension

private extension DateFormatter {
    static let presetName: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMdd-HHmm"
        return formatter
    }()
}

// MARK: - Preview

struct QuickPresetDropdown_Previews: PreviewProvider {
    static var previews: some View {
        QuickPresetDropdown()
            .environmentObject(ClickItViewModel())
            .frame(width: 400)
            .padding()
    }
}