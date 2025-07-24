//
//  StatusHeaderCard.swift
//  ClickIt
//
//  Created by ClickIt on 2025-07-13.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import SwiftUI

struct StatusHeaderCard: View {
    @ObservedObject var viewModel: ClickItViewModel
    @ObservedObject var timeManager: ElapsedTimeManager = ElapsedTimeManager.shared
    @ObservedObject var hotkeyManager: HotkeyManager = HotkeyManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // App Icon and Title Row
            HStack(spacing: 12) {
                // App Icon with blue target symbol
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "target")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("ClickIt")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // App Status
                    HStack(spacing: 6) {
                        Circle()
                            .fill(viewModel.appStatus.color)
                            .frame(width: 8, height: 8)
                        
                        Text(viewModel.appStatus.displayText)
                            .font(.subheadline)
                            .foregroundColor(viewModel.appStatus.color)
                    }
                    
                    // Emergency Stop Status
                    if hotkeyManager.emergencyStopActivated {
                        HStack(spacing: 6) {
                            Image(systemName: "stop.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 12))
                            
                            Text("EMERGENCY STOP ACTIVE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(4)
                    } else if viewModel.emergencyStopEnabled {
                        HStack(spacing: 6) {
                            Image(systemName: "shield.checkered")
                                .foregroundColor(.green)
                                .font(.system(size: 12))
                            
                            Text("Emergency Stop: \(viewModel.selectedEmergencyStopKey.description)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
            }
            
            // Statistics Grid
            HStack(spacing: 16) {
                StatisticView(
                    title: "Clicks",
                    value: "\(viewModel.statistics?.totalClicks ?? 0)",
                    icon: "cursorarrow.click"
                )
                
                ElapsedTimeStatisticView(
                    timeManager: timeManager,
                    fallbackStatistics: viewModel.statistics
                )
                
                StatisticView(
                    title: "Success",
                    value: viewModel.statistics?.formattedSuccessRate ?? "100.0%",
                    icon: "checkmark.circle"
                )
            }
            
            // Control Buttons
            if viewModel.isRunning || viewModel.isPaused {
                // Running/Paused state: Show Pause/Resume and Stop buttons
                HStack(spacing: 12) {
                    // Pause/Resume Button
                    Button(action: {
                        if viewModel.canPause {
                            viewModel.pauseAutomation()
                        } else if viewModel.canResume {
                            viewModel.resumeAutomation()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                                .font(.system(size: 14, weight: .medium))
                            
                            Text(viewModel.isPaused ? "Resume" : "Pause")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!viewModel.canPause && !viewModel.canResume)
                    .tint(viewModel.isPaused ? .green : .orange)
                    
                    // Stop Button
                    Button(action: {
                        viewModel.stopAutomation()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 14, weight: .medium))
                            
                            Text("Stop")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            } else {
                // Ready state: Show Start button
                Button(action: {
                    viewModel.startAutomation()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("Start Automation")
                            .font(.headline)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canStartAutomation)
                .tint(.green)
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct StatisticView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.blue)
            
            Text(value)
                .font(.system(.title3, design: .monospaced))
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(8)
    }
}

struct StatusHeaderCard_Previews: PreviewProvider {
    static var previews: some View {
        StatusHeaderCard(viewModel: ClickItViewModel())
            .frame(width: 400)
            .padding()
    }
}
