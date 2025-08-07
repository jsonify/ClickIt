//
//  PresetsTab.swift
//  ClickIt
//
//  Created by ClickIt on 2025-08-06.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import SwiftUI

/// Main presets tab containing all preset management functionality
struct PresetsTab: View {
    @EnvironmentObject private var viewModel: ClickItViewModel
    @ObservedObject private var presetManager = PresetManager.shared
    
    @State private var selectedPresetId: UUID?
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with icon and loading indicator
            headerSection
            
            // Preset list
            CompactPresetList(
                selectedPresetId: $selectedPresetId,
                onPresetLoad: loadPreset,
                onPresetSelect: { preset in
                    selectedPresetId = preset.id
                }
            )
            
            // Action buttons (save, load, rename, delete)
            PresetActions(
                viewModel: viewModel,
                selectedPresetId: $selectedPresetId
            )
            
            // Import/Export section
            PresetImportExport()
            
            // Error display
            if let error = presetManager.lastError {
                errorMessageView(error)
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            // Reload presets when tab appears
            presetManager.reloadPresets()
        }
    }
    
    @ViewBuilder
    private var headerSection: some View {
        HStack {
            Image(systemName: "folder.circle.fill")
                .foregroundColor(.blue)
                .font(.system(size: 20))
            
            Text("Preset Management")
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            if presetManager.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(.horizontal, 4)
    }
    
    @ViewBuilder
    private func errorMessageView(_ error: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.orange)
                .font(.system(size: 14))
            
            Text(error)
                .font(.subheadline)
                .foregroundColor(.orange)
                .lineLimit(2)
            
            Spacer()
            
            Button("Dismiss") {
                presetManager.lastError = nil
            }
            .buttonStyle(.borderless)
            .font(.caption)
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func loadPreset(_ preset: PresetConfiguration) {
        presetManager.applyPreset(preset, to: viewModel)
        print("PresetsTab: Loaded preset '\(preset.name)'")
    }
}

// MARK: - Preview

struct PresetsTab_Previews: PreviewProvider {
    static var previews: some View {
        PresetsTab()
            .environmentObject(ClickItViewModel())
            .frame(width: 400, height: 600)
            .padding()
    }
}