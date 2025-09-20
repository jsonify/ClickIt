//
//  PresetActions.swift
//  ClickIt
//
//  Created by ClickIt on 2025-08-06.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import SwiftUI

/// Preset management actions (save, rename, delete, clear)
struct PresetActions: View {
    @ObservedObject var presetManager = PresetManager.shared
    @ObservedObject var viewModel: ClickItViewModel
    
    @Binding var selectedPresetId: UUID?
    @State private var showingSaveDialog = false
    @State private var showingRenameDialog = false
    @State private var showingDeleteConfirmation = false
    @State private var newPresetName = ""
    @State private var renamePresetName = ""
    
    private var selectedPreset: PresetConfiguration? {
        selectedPresetId.flatMap { id in
            presetManager.availablePresets.first { $0.id == id }
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Primary actions row
            HStack(spacing: 12) {
                // Save current settings
                Button(action: {
                    showingSaveDialog = true
                }) {
                    Label("Save Current", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isRunning)
                
                // Load selected preset
                Button(action: {
                    if let preset = selectedPreset {
                        loadPreset(preset)
                    }
                }) {
                    Label("Load", systemImage: "arrow.down.circle")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(selectedPreset == nil || viewModel.isRunning)
            }
            
            // Secondary actions row
            HStack(spacing: 12) {
                // Rename selected preset
                Button(action: {
                    if let preset = selectedPreset {
                        renamePresetName = preset.name
                        showingRenameDialog = true
                    }
                }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity, minHeight: 28)
                }
                .buttonStyle(.bordered)
                .disabled(selectedPreset == nil || viewModel.isRunning)
                .help("Rename selected preset")
                
                // Delete selected preset
                Button(action: {
                    showingDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity, minHeight: 28)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(selectedPreset == nil || viewModel.isRunning)
                .help("Delete selected preset")
                
                // Clear all presets
                Button(action: {
                    presetManager.clearAllPresets()
                    selectedPresetId = nil
                }) {
                    Image(systemName: "trash.slash")
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity, minHeight: 28)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(presetManager.availablePresets.isEmpty || viewModel.isRunning)
                .help("Clear all presets")
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        
        // Dialogs
        .sheet(isPresented: $showingSaveDialog) {
            savePresetDialog
        }
        .sheet(isPresented: $showingRenameDialog) {
            renamePresetDialog
        }
        .alert("Delete Preset", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let preset = selectedPreset {
                    presetManager.deletePreset(id: preset.id)
                    selectedPresetId = nil
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete '\(selectedPreset?.name ?? "")'? This action cannot be undone.")
        }
    }
    
    // MARK: - Save Preset Dialog
    
    @ViewBuilder
    private var savePresetDialog: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "bookmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                
                Text("Save Current Configuration")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Enter a name for this preset configuration:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("Preset Name", text: $newPresetName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        saveCurrentPreset()
                    }
                
                HStack(spacing: 16) {
                    Button("Cancel") {
                        showingSaveDialog = false
                        newPresetName = ""
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Save") {
                        saveCurrentPreset()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newPresetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(24)
            .frame(width: 350)
            .navigationTitle("Save Preset")
        }
        .onAppear {
            // Generate a default name
            let timestamp = DateFormatter.presetName.string(from: Date())
            newPresetName = "Preset \(timestamp)"
        }
    }
    
    // MARK: - Rename Preset Dialog
    
    @ViewBuilder
    private var renamePresetDialog: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
                
                Text("Rename Preset")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Enter a new name for this preset:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("Preset Name", text: $renamePresetName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        renameSelectedPreset()
                    }
                
                HStack(spacing: 16) {
                    Button("Cancel") {
                        showingRenameDialog = false
                        renamePresetName = ""
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Rename") {
                        renameSelectedPreset()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(renamePresetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(24)
            .frame(width: 350)
            .navigationTitle("Rename Preset")
        }
    }
    
    // MARK: - Actions
    
    private func saveCurrentPreset() {
        let trimmedName = newPresetName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let success = presetManager.savePresetFromViewModel(viewModel, name: trimmedName)
        if success {
            showingSaveDialog = false
            newPresetName = ""
            print("PresetActions: Saved preset '\(trimmedName)'")
        }
        // Error handling is managed by PresetManager and displayed elsewhere
    }
    
    private func renameSelectedPreset() {
        guard let preset = selectedPreset else { return }
        let trimmedName = renamePresetName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let success = presetManager.renamePreset(id: preset.id, to: trimmedName)
        if success {
            showingRenameDialog = false
            renamePresetName = ""
            print("PresetActions: Renamed preset to '\(trimmedName)'")
        }
        // Error handling is managed by PresetManager and displayed elsewhere
    }
    
    private func loadPreset(_ preset: PresetConfiguration) {
        presetManager.applyPreset(preset, to: viewModel)
        print("PresetActions: Loaded preset '\(preset.name)'")
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

struct PresetActions_Previews: PreviewProvider {
    @State static var selectedId: UUID? = nil
    
    static var previews: some View {
        PresetActions(
            viewModel: ClickItViewModel(),
            selectedPresetId: $selectedId
        )
        .frame(width: 400)
        .padding()
    }
}