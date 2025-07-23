import SwiftUI
import UniformTypeIdentifiers

/// UI component for managing automation presets
struct PresetSelectionView: View {
    // MARK: - Environment and State
    
    @ObservedObject var presetManager = PresetManager.shared
    @ObservedObject var viewModel: ClickItViewModel
    
    @State private var selectedPresetId: UUID?
    @State private var showingSavePresetDialog = false
    @State private var showingRenameDialog = false
    @State private var showingDeleteConfirmation = false
    @State private var showingImportFileDialog = false
    @State private var showingExportFileDialog = false
    @State private var newPresetName = ""
    @State private var renamePresetName = ""
    @State private var presetToDelete: PresetConfiguration?
    @State private var presetToRename: PresetConfiguration?
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 12) {
            headerSection
            presetSelectionSection
            actionButtonsSection
            
            if let error = presetManager.lastError {
                errorMessageView(error)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
        .alert("Save Preset", isPresented: $showingSavePresetDialog) {
            savePresetDialog
        } message: {
            Text("Enter a name for this preset configuration")
        }
        .alert("Rename Preset", isPresented: $showingRenameDialog) {
            renamePresetDialog
        } message: {
            Text("Enter a new name for '\(presetToRename?.name ?? "")'")
        }
        .alert("Delete Preset", isPresented: $showingDeleteConfirmation) {
            deleteConfirmationDialog
        } message: {
            Text("Are you sure you want to delete '\(presetToDelete?.name ?? "")'? This action cannot be undone.")
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
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
            defaultFilename: "ClickIt-Presets"
        ) { result in
            handleExportResult(result)
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        HStack {
            Image(systemName: "bookmark.circle.fill")
                .foregroundColor(.blue)
                .font(.title2)
            
            Text("Presets")
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            if presetManager.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
    }
    
    private var presetSelectionSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Available Presets:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(presetManager.presetCount) preset(s)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if presetManager.availablePresets.isEmpty {
                emptyPresetsView
            } else {
                presetListView
            }
        }
    }
    
    private var emptyPresetsView: some View {
        VStack(spacing: 8) {
            Image(systemName: "bookmark.slash")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("No Presets Saved")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Save your current configuration as a preset to quickly load it later")
                .font(.caption)
                .foregroundColor(Color(NSColor.tertiaryLabelColor))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(minHeight: 80)
        .frame(maxWidth: .infinity)
        .background(Color(NSColor.quaternaryLabelColor).opacity(0.3))
        .cornerRadius(8)
    }
    
    private var presetListView: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(presetManager.availablePresets) { preset in
                    presetRowView(preset)
                }
            }
        }
        .frame(maxHeight: 120)
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(6)
    }
    
    private func presetRowView(_ preset: PresetConfiguration) -> some View {
        HStack(spacing: 8) {
            // Selection indicator
            Circle()
                .fill(selectedPresetId == preset.id ? Color.blue : Color.clear)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(Color.secondary, lineWidth: 1)
                )
            
            // Preset info
            VStack(alignment: .leading, spacing: 2) {
                Text(preset.name)
                    .font(.subheadline)
                    .fontWeight(selectedPresetId == preset.id ? .semibold : .regular)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    Text("\(preset.estimatedCPS, specifier: "%.1f") CPS")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(preset.durationMode.displayName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if let target = preset.targetPoint {
                        Text("(\(Int(target.x)), \(Int(target.y)))")
                            .font(.caption2)
                            .foregroundColor(Color(NSColor.tertiaryLabelColor))
                    }
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 4) {
                Button {
                    loadPreset(preset)
                } label: {
                    Image(systemName: "square.and.arrow.down")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .help("Load this preset")
                
                Button {
                    presetToRename = preset
                    renamePresetName = preset.name
                    showingRenameDialog = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .help("Rename this preset")
                
                Button {
                    presetToDelete = preset
                    showingDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .buttonStyle(.borderless)
                .help("Delete this preset")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            selectedPresetId == preset.id 
                ? Color.blue.opacity(0.1)
                : Color.clear
        )
        .cornerRadius(6)
        .onTapGesture {
            selectedPresetId = selectedPresetId == preset.id ? nil : preset.id
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 8) {
            // Primary actions
            HStack(spacing: 8) {
                Button {
                    showingSavePresetDialog = true
                    newPresetName = ""
                } label: {
                    Label("Save Current", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canSaveCurrentConfiguration)
                .help("Save current configuration as a new preset")
                
                if let selectedId = selectedPresetId,
                   let selectedPreset = presetManager.availablePresets.first(where: { $0.id == selectedId }) {
                    Button {
                        loadPreset(selectedPreset)
                    } label: {
                        Label("Load Selected", systemImage: "arrow.down.circle.fill")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                    .help("Load the selected preset")
                }
            }
            
            // Secondary actions
            HStack(spacing: 8) {
                Button {
                    showingImportFileDialog = true
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .help("Import presets from file")
                
                Button {
                    showingExportFileDialog = true
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .disabled(presetManager.availablePresets.isEmpty)
                .help("Export all presets to file")
                
                Spacer()
                
                if !presetManager.availablePresets.isEmpty {
                    Button {
                        showingDeleteConfirmation = true
                        presetToDelete = nil // Will trigger "clear all" confirmation
                    } label: {
                        Label("Clear All", systemImage: "trash.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.borderless)
                    .help("Delete all presets")
                }
            }
        }
    }
    
    private func errorMessageView(_ error: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            Text(error)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            Spacer()
            
            Button("Dismiss") {
                presetManager.lastError = nil
            }
            .font(.caption)
            .buttonStyle(.borderless)
        }
        .padding(8)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(6)
    }
    
    // MARK: - Dialog Components
    
    private var savePresetDialog: some View {
        Group {
            TextField("Preset name", text: $newPresetName)
                .textFieldStyle(.roundedBorder)
            
            HStack {
                Button("Cancel") {
                    showingSavePresetDialog = false
                    newPresetName = ""
                }
                
                Button("Save") {
                    saveCurrentPreset()
                }
                .disabled(newPresetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
    
    private var renamePresetDialog: some View {
        Group {
            TextField("New name", text: $renamePresetName)
                .textFieldStyle(.roundedBorder)
            
            HStack {
                Button("Cancel") {
                    showingRenameDialog = false
                    presetToRename = nil
                    renamePresetName = ""
                }
                
                Button("Rename") {
                    renameSelectedPreset()
                }
                .disabled(renamePresetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
    
    private var deleteConfirmationDialog: some View {
        Group {
            HStack {
                Button("Cancel") {
                    showingDeleteConfirmation = false
                    presetToDelete = nil
                }
                
                Button("Delete", role: .destructive) {
                    deleteSelectedPreset()
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var canSaveCurrentConfiguration: Bool {
        return viewModel.targetPoint != nil && viewModel.totalMilliseconds > 0
    }
    
    // MARK: - Actions
    
    private func saveCurrentPreset() {
        let trimmedName = newPresetName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            showError("Preset name cannot be empty")
            return
        }
        
        guard presetManager.isPresetNameAvailable(trimmedName) else {
            showError("A preset with this name already exists")
            return
        }
        
        if presetManager.savePresetFromViewModel(viewModel, name: trimmedName) {
            showingSavePresetDialog = false
            newPresetName = ""
            // Select the newly saved preset
            if let newPreset = presetManager.availablePresets.first(where: { $0.name == trimmedName }) {
                selectedPresetId = newPreset.id
            }
        } else {
            showError(presetManager.lastError ?? "Failed to save preset")
        }
    }
    
    private func loadPreset(_ preset: PresetConfiguration) {
        presetManager.applyPreset(preset, to: viewModel)
        selectedPresetId = preset.id
    }
    
    private func renameSelectedPreset() {
        guard let preset = presetToRename else { return }
        
        let trimmedName = renamePresetName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if presetManager.renamePreset(id: preset.id, to: trimmedName) {
            showingRenameDialog = false
            presetToRename = nil
            renamePresetName = ""
        } else {
            showError(presetManager.lastError ?? "Failed to rename preset")
        }
    }
    
    private func deleteSelectedPreset() {
        if let preset = presetToDelete {
            // Delete specific preset
            if presetManager.deletePreset(id: preset.id) {
                if selectedPresetId == preset.id {
                    selectedPresetId = nil
                }
            } else {
                showError(presetManager.lastError ?? "Failed to delete preset")
            }
        } else {
            // Clear all presets
            if presetManager.clearAllPresets() {
                selectedPresetId = nil
            } else {
                showError(presetManager.lastError ?? "Failed to clear all presets")
            }
        }
        
        showingDeleteConfirmation = false
        presetToDelete = nil
    }
    
    private func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            do {
                let data = try Data(contentsOf: url)
                let importedCount = presetManager.importAllPresets(from: data, replaceExisting: false)
                
                if importedCount > 0 {
                    // Success feedback could be added here
                } else {
                    showError("No valid presets found in the selected file")
                }
            } catch {
                showError("Failed to read file: \(error.localizedDescription)")
            }
            
        case .failure(let error):
            showError("Import failed: \(error.localizedDescription)")
        }
    }
    
    private func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success:
            // Success feedback could be added here
            break
        case .failure(let error):
            showError("Export failed: \(error.localizedDescription)")
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingErrorAlert = true
    }
}

// MARK: - Supporting Types

/// Document type for exporting presets
struct ExportablePresetDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    let presets: [PresetConfiguration]
    
    init(presets: [PresetConfiguration]) {
        self.presets = presets
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.presets = try decoder.decode([PresetConfiguration].self, from: data)
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder.encode(presets)
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Preview

struct PresetSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        PresetSelectionView(viewModel: ClickItViewModel())
            .frame(width: 400)
            .padding()
    }
}