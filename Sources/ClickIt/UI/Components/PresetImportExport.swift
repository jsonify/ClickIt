//
//  PresetImportExport.swift
//  ClickIt
//
//  Created by ClickIt on 2025-08-06.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import SwiftUI
import UniformTypeIdentifiers

/// Import and export functionality for presets
struct PresetImportExport: View {
    @ObservedObject var presetManager = PresetManager.shared
    
    @State private var showingImportFileDialog = false
    @State private var showingExportFileDialog = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Image(systemName: "arrow.up.arrow.down.circle")
                    .foregroundColor(.blue)
                    .font(.system(size: 14))
                
                Text("Import / Export")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            // Import/Export buttons
            HStack(spacing: 12) {
                // Import button
                Button(action: {
                    showingImportFileDialog = true
                }) {
                    Label("Import", systemImage: "square.and.arrow.down")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, minHeight: 32)
                }
                .buttonStyle(.bordered)
                .help("Import presets from JSON file")
                
                // Export button
                Button(action: {
                    showingExportFileDialog = true
                }) {
                    Label("Export", systemImage: "square.and.arrow.up")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, minHeight: 32)
                }
                .buttonStyle(.bordered)
                .disabled(presetManager.availablePresets.isEmpty)
                .help("Export all presets to JSON file")
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        
        // File dialogs
        .fileImporter(
            isPresented: $showingImportFileDialog,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImportResult(result)
        }
        .fileExporter(
            isPresented: $showingExportFileDialog,
            document: ExportablePresetDocument(presets: presetManager.availablePresets),
            contentType: .json,
            defaultFilename: "ClickIt-Presets-\(DateFormatter.exportFilename.string(from: Date()))"
        ) { result in
            handleExportResult(result)
        }
        
        // Error alert
        .alert("Import/Export Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Import/Export Handlers
    
    private func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                showError("No file selected for import")
                return
            }
            
            do {
                let data = try Data(contentsOf: url)
                let importCount = presetManager.importAllPresets(from: data, replaceExisting: false)
                
                if importCount > 0 {
                    print("PresetImportExport: Successfully imported \(importCount) preset(s)")
                } else {
                    showError("No valid presets found in the imported file")
                }
            } catch {
                showError("Failed to import presets: \(error.localizedDescription)")
            }
            
        case .failure(let error):
            showError("Import failed: \(error.localizedDescription)")
        }
    }
    
    private func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            print("PresetImportExport: Successfully exported presets to \(url.path)")
            
        case .failure(let error):
            showError("Export failed: \(error.localizedDescription)")
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingErrorAlert = true
        print("PresetImportExport: Error - \(message)")
    }
}

// ExportablePresetDocument is already defined in PresetSelectionView.swift

// MARK: - DateFormatter Extension

private extension DateFormatter {
    static let exportFilename: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmm"
        return formatter
    }()
}

// MARK: - Preview

struct PresetImportExport_Previews: PreviewProvider {
    static var previews: some View {
        PresetImportExport()
            .frame(width: 400)
            .padding()
    }
}