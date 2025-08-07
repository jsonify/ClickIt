//
//  InlineTimingControls.swift
//  ClickIt
//
//  Created by ClickIt on 2025-08-06.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import SwiftUI

struct InlineTimingControls: View {
    @EnvironmentObject private var viewModel: ClickItViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "timer")
                    .foregroundColor(.blue)
                    .font(.system(size: 14))
                
                Text("Click Interval")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                // Quick CPS display
                Text(String(format: "~%.1f CPS", viewModel.estimatedCPS))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.green)
                    .fontWeight(.semibold)
            }
            
            // Single row time input
            HStack(spacing: 8) {
                CompactTimeField(label: "H", value: $viewModel.intervalHours, range: 0...23, width: 35)
                Text(":")
                    .foregroundColor(.secondary)
                CompactTimeField(label: "M", value: $viewModel.intervalMinutes, range: 0...59, width: 35)
                Text(":")
                    .foregroundColor(.secondary)
                CompactTimeField(label: "S", value: $viewModel.intervalSeconds, range: 0...59, width: 35)
                Text(".")
                    .foregroundColor(.secondary)
                CompactTimeField(label: "MS", value: $viewModel.intervalMilliseconds, range: 0...999, width: 45)
                
                Spacer()
                
                // Total time display
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatTotalTime(viewModel.totalMilliseconds))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                    
                    Text("Total")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
            
            // Validation message
            if viewModel.totalMilliseconds <= 0 {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                        .font(.system(size: 10))
                    
                    Text("Interval must be greater than 0")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    
                    Spacer()
                }
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func formatTotalTime(_ milliseconds: Int) -> String {
        if milliseconds < 1000 {
            return "\(milliseconds)ms"
        } else if milliseconds < 60000 {
            let seconds = Double(milliseconds) / 1000.0
            return String(format: "%.1fs", seconds)
        } else {
            let totalSeconds = milliseconds / 1000
            let minutes = totalSeconds / 60
            let seconds = totalSeconds % 60
            let ms = milliseconds % 1000
            
            if ms > 0 {
                return "\(minutes)m \(seconds)s \(ms)ms"
            } else if seconds > 0 {
                return "\(minutes)m \(seconds)s"
            } else {
                return "\(minutes)m"
            }
        }
    }
}

// Compact time input field for inline layout
private struct CompactTimeField: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let width: CGFloat
    
    @FocusState private var isFocused: Bool
    @State private var textValue: String = ""
    
    var body: some View {
        VStack(spacing: 2) {
            TextField("0", text: $textValue)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.center)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.medium)
                .frame(width: width)
                .focused($isFocused)
                .onChange(of: textValue) { _, newValue in
                    updateValueFromText(newValue)
                }
                .onChange(of: value) { _, newValue in
                    if !isFocused {
                        textValue = String(newValue)
                    }
                }
                .onAppear {
                    textValue = String(value)
                }
            
            Text(label)
                .font(.system(size: 8))
                .foregroundColor(.secondary)
                .fontWeight(.medium)
        }
    }
    
    private func updateValueFromText(_ text: String) {
        // Allow empty text while editing
        if text.isEmpty && isFocused {
            return
        }
        
        // Parse and validate the number
        if let number = Int(text), range.contains(number) {
            value = number
        } else if !text.isEmpty {
            // Invalid input - revert to current value
            textValue = String(value)
        } else {
            // Empty input when not focused - set to 0 if in range
            value = range.contains(0) ? 0 : range.lowerBound
            textValue = String(value)
        }
    }
}

// MARK: - Preview

struct InlineTimingControls_Previews: PreviewProvider {
    static var previews: some View {
        InlineTimingControls()
            .environmentObject({
                let vm = ClickItViewModel()
                vm.intervalSeconds = 1
                vm.intervalMilliseconds = 500
                return vm
            }())
            .frame(width: 400)
            .padding()
    }
}