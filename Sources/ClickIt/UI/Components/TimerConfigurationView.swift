//
//  TimerConfigurationView.swift
//  ClickIt
//
//  Created by ClickIt on 2025-07-13.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import SwiftUI

struct TimerConfigurationView: View {
    @ObservedObject var viewModel: ClickItViewModel
    var onCancel: () -> Void = {}
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with close button
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.blue)
                Text("Auto Click Timer Mode")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 20))
                }
                .buttonStyle(.plain)
            }
            
            // Timer Duration Configuration
            VStack(alignment: .leading, spacing: 8) {
                Text("Timer Duration:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 12) {
                    // Minutes input
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Minutes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("0", value: $viewModel.timerDurationMinutes, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                            .onChange(of: viewModel.timerDurationMinutes) { _, newValue in
                                // Clamp to valid range (0-60 minutes)
                                viewModel.timerDurationMinutes = max(0, min(60, newValue))
                            }
                    }
                    
                    // Seconds input
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Seconds")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("10", value: $viewModel.timerDurationSeconds, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                            .onChange(of: viewModel.timerDurationSeconds) { _, newValue in
                                // Clamp to valid range (0-59 seconds)
                                viewModel.timerDurationSeconds = max(0, min(59, newValue))
                            }
                    }
                    
                    Spacer()
                    
                    // Total time display
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Total")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatTotalTime(viewModel.totalTimerSeconds))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(viewModel.isValidTimerDuration ? .primary : .red)
                    }
                }
            }
            
            // Validation message
            if !viewModel.isValidTimerDuration {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Timer duration must be between 1 second and 60 minutes")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
            }
            
            // Start button
            Button(action: startTimerAction) {
                HStack {
                    Image(systemName: "play.circle.fill")
                    Text("Start Timer & Auto Click")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.isValidTimerDuration || viewModel.timerIsActive)
            
            // Guidance text
            HStack {
                Image(systemName: "lightbulb")
                    .foregroundColor(.blue)
                Text("Position cursor where you want clicking to start, then wait...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(6)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - Helper Methods
    
    private func startTimerAction() {
        viewModel.timerMode = .countdown
        viewModel.startAutomation() // This will now trigger timer mode
    }
    
    private func formatTotalTime(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        } else {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            if remainingSeconds == 0 {
                return "\(minutes)m"
            } else {
                return "\(minutes)m \(remainingSeconds)s"
            }
        }
    }
}

#Preview {
    TimerConfigurationView(viewModel: {
        let vm = ClickItViewModel()
        vm.timerDurationMinutes = 0
        vm.timerDurationSeconds = 15
        return vm
    }())
    .frame(width: 350)
    .padding()
}