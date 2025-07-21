//
//  ActiveTimerView.swift
//  ClickIt
//
//  Created by ClickIt on 2025-07-13.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import SwiftUI

struct ActiveTimerView: View {
    @ObservedObject var viewModel: ClickItViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with timer icon
            HStack {
                Image(systemName: "timer")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("Starting Auto Click in...")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            // Large countdown display
            Text(timeString(from: viewModel.remainingTime))
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundColor(.blue)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
            
            // Progress indicator
            ProgressView(value: progressValue)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .frame(height: 6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(3)
            
            // Instruction text
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "target")
                        .foregroundColor(.blue)
                    Text("Move cursor to target location")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                Text("Clicking will begin automatically when timer reaches zero")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 8)
            
            // Cancel button
            Button(action: {
                viewModel.cancelTimer()
            }) {
                HStack {
                    Image(systemName: "stop.circle.fill")
                    Text("Cancel Timer")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .foregroundColor(.red)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.05))
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.3), value: viewModel.remainingTime)
    }
    
    // MARK: - Helper Methods
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var progressValue: Double {
        let totalDuration = Double(viewModel.totalTimerSeconds)
        guard totalDuration > 0 else { return 0.0 }
        
        let elapsed = totalDuration - viewModel.remainingTime
        return elapsed / totalDuration
    }
}

struct ActiveTimerView_Previews: PreviewProvider {
    static var previews: some View {
        ActiveTimerView(viewModel: {
            let vm = ClickItViewModel()
            vm.isCountingDown = true
            vm.remainingTime = 123 // 2:03
            vm.timerDurationMinutes = 2
            vm.timerDurationSeconds = 30
            return vm
        }())
        .frame(width: 350)
        .padding()
    }
}