//
//  TargetPointSelectionCard.swift
//  ClickIt
//
//  Created by ClickIt on 2025-07-13.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import SwiftUI

struct TargetPointSelectionCard: View {
    @ObservedObject var viewModel: ClickItViewModel
    @State private var isSelecting = false
    @State private var showingManualInput = false
    @State private var showingTimerMode = false
    @State private var manualX: String = ""
    @State private var manualY: String = ""
    @State private var validationError: String?
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with Icon
            HStack {
                Image(systemName: "target")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
                
                Text("Target Point")
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            // Coordinate Display
            VStack(spacing: 12) {
                if let point = viewModel.targetPoint {
                    // Selected coordinates display
                    HStack(spacing: 16) {
                        CoordinateDisplay(label: "X", value: Int(point.x))
                        CoordinateDisplay(label: "Y", value: Int(point.y))
                        
                        Spacer()
                        
                        // Status indicator
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 14))
                            Text("Point Set")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    .padding(12)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                } else {
                    // No point selected
                    HStack {
                        Text("No target point selected")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle")
                                .foregroundColor(.orange)
                                .font(.system(size: 14))
                            Text("Required")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Show timer UI if countdown is active
                if viewModel.isCountingDown {
                    ActiveTimerView(viewModel: viewModel)
                        .transition(.opacity)
                } else if showingTimerMode {
                    TimerConfigurationView(viewModel: viewModel) {
                        // Close timer mode
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingTimerMode = false
                        }
                    }
                    .transition(.opacity)
                } else {
                    // Action Buttons
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            // Primary action button
                            Button(action: startClickSelection) {
                                HStack(spacing: 6) {
                                    Image(systemName: isSelecting ? "stop.circle" : "hand.tap")
                                        .font(.system(size: 14))
                                    Text(isSelecting ? "Cancel" : "Click to Set Point")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isSelecting)
                            .tint(isSelecting ? .red : .blue)
                            
                            // Manual input button
                            Button(action: { showingManualInput.toggle() }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "keyboard")
                                        .font(.system(size: 14))
                                    Text("Manual Input")
                                        .font(.subheadline)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        // Timer mode button
                        Button(action: { 
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingTimerMode.toggle()
                                showingManualInput = false // Close manual input if open
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "clock")
                                    .font(.system(size: 14))
                                Text("Auto Click Timer")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.timerIsActive)
                    }
                }
                
                // Manual input section
                if showingManualInput && !viewModel.isCountingDown && !showingTimerMode {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("X Coordinate")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                TextField("X", text: $manualX)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Y Coordinate")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                TextField("Y", text: $manualY)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                        
                        Button("Set Point") {
                            setManualPoint()
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                        .disabled(manualX.isEmpty || manualY.isEmpty)
                    }
                    .padding(12)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    .transition(.opacity)
                }
                
                // Validation error
                if let error = validationError {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                            .font(.system(size: 12))
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                    .padding(8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
                }
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .onChange(of: viewModel.isCountingDown) { _, isCountingDown in
            if isCountingDown {
                // Hide other UI elements when timer starts
                showingManualInput = false
                showingTimerMode = false
            }
        }
        .onChange(of: viewModel.timerMode) { _, mode in
            if mode == .off {
                // Reset timer UI state when timer mode is turned off
                showingTimerMode = false
            }
        }
    }
    
    // MARK: - Private Methods
    private func startClickSelection() {
        isSelecting = true
        clearValidationError()
        
        Task { @MainActor in
            ClickCoordinateCapture.captureNextClick { point in
                self.handleCapturedPoint(point)
            }
        }
    }
    
    private func handleCapturedPoint(_ point: CGPoint) {
        isSelecting = false
        
        if validateCoordinates(point) {
            viewModel.setTargetPoint(point)
        }
    }
    
    private func setManualPoint() {
        clearValidationError()
        
        guard let x = Double(manualX), let y = Double(manualY) else {
            validationError = "Invalid coordinates. Please enter valid numbers."
            return
        }
        
        let point = CGPoint(x: x, y: y)
        
        if validateCoordinates(point) {
            viewModel.setTargetPoint(point)
            showingManualInput = false
            manualX = ""
            manualY = ""
        }
    }
    
    private func validateCoordinates(_ point: CGPoint) -> Bool {
        let screenFrame = NSScreen.main?.frame ?? CGRect.zero
        
        if point.x < 0 || point.x > screenFrame.width || 
           point.y < 0 || point.y > screenFrame.height {
            validationError = "Coordinates must be within screen bounds (0,0) to (\(Int(screenFrame.width)),\(Int(screenFrame.height)))"
            return false
        }
        
        return true
    }
    
    private func clearValidationError() {
        validationError = nil
    }
}

struct CoordinateDisplay: View {
    let label: String
    let value: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text("\(value)")
                .font(.system(.title3, design: .monospaced))
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    TargetPointSelectionCard(viewModel: {
        let vm = ClickItViewModel()
        vm.setTargetPoint(CGPoint(x: 1007, y: 260))
        return vm
    }())
    .frame(width: 400)
    .padding()
}
