//
//  CompactPresetList.swift
//  ClickIt
//
//  Created by ClickIt on 2025-08-06.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import SwiftUI

/// Compact table-style preset list for the Presets tab
struct CompactPresetList: View {
    @ObservedObject var presetManager = PresetManager.shared
    @Binding var selectedPresetId: UUID?
    let onPresetLoad: (PresetConfiguration) -> Void
    let onPresetSelect: (PresetConfiguration) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text("Available Presets:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(presetManager.availablePresets.count) preset(s)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if presetManager.availablePresets.isEmpty {
                emptyPresetsView
            } else {
                presetTableView
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    @ViewBuilder
    private var emptyPresetsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            
            Text("No Presets Available")
                .font(.headline)
                .fontWeight(.medium)
            
            Text("Save your current configuration to create your first preset.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .padding()
    }
    
    @ViewBuilder
    private var presetTableView: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(presetManager.availablePresets) { preset in
                    PresetRowView(
                        preset: preset,
                        isSelected: selectedPresetId == preset.id,
                        onSelect: { onPresetSelect(preset) },
                        onLoad: { onPresetLoad(preset) }
                    )
                }
            }
            .padding(.vertical, 4)
        }
        .frame(maxHeight: 200)
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(6)
    }
}

/// Individual preset row in the compact table
private struct PresetRowView: View {
    let preset: PresetConfiguration
    let isSelected: Bool
    let onSelect: () -> Void
    let onLoad: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection indicator
            Button(action: onSelect) {
                Circle()
                    .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.5), lineWidth: 2)
                    .fill(isSelected ? Color.accentColor : Color.clear)
                    .frame(width: 12, height: 12)
            }
            .buttonStyle(.plain)
            
            // Preset info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(preset.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Quick stats
                    HStack(spacing: 6) {
                        Text(String(format: "%.1f CPS", preset.estimatedCPS))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.blue)
                        
                        Text(preset.durationMode.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Additional details
                HStack {
                    if let targetPoint = preset.targetPoint {
                        Label("(\(Int(targetPoint.x)), \(Int(targetPoint.y)))", systemImage: "target")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .labelStyle(.titleAndIcon)
                    } else {
                        Label("No target set", systemImage: "target")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .labelStyle(.titleAndIcon)
                    }
                    
                    Spacer()
                    
                    Text(preset.createdAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Load button
            if isHovered || isSelected {
                Button(action: onLoad) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .help("Load this preset")
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : 
                      (isHovered ? Color.secondary.opacity(0.05) : Color.clear))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Preview

struct CompactPresetList_Previews: PreviewProvider {
    @State static var selectedId: UUID? = nil
    
    static var previews: some View {
        CompactPresetList(
            selectedPresetId: $selectedId,
            onPresetLoad: { _ in },
            onPresetSelect: { _ in }
        )
        .frame(width: 400)
        .padding()
    }
}