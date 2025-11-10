//
//  QuickStartTab.swift
//  ClickIt
//
//  Created by ClickIt on 2025-08-06.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import SwiftUI

struct QuickStartTab: View {
    @EnvironmentObject private var viewModel: ClickItViewModel
    @ObservedObject private var timeManager = ElapsedTimeManager.shared
    @ObservedObject private var hotkeyManager = HotkeyManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Statistics Row (fixed at top)
            statisticsRow
                .padding(.horizontal, 16)
                .padding(.top, 8)

            // Emergency Stop Information (fixed at top for safety)
            emergencyStopInfo
                .padding(.horizontal, 16)
                .padding(.top, 12)

            // Scrollable content area
            ScrollView {
                VStack(spacing: 16) {
                    // Target Point Selector (with Timer Support)
                    TargetPointSelectionCard(viewModel: viewModel)

                    // Active Target Mode Toggle
                    ActiveTargetModeCard()

                    // Inline Timing Controls
                    InlineTimingControls()

                    // Inline Scheduling Controls
                    InlineSchedulingControls()

                    // Quick Preset Selection
                    QuickPresetDropdown()

                    // Main Control Button
                    mainControlButton
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 20) // Extra bottom padding for better scroll feel
            }
        }
    }
    
    @ViewBuilder
    private var statusHeader: some View {
        HStack(spacing: 12) {
            // App Icon
            Image(systemName: "target")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("ClickIt")
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(viewModel.appStatus.color)
                        .frame(width: 8, height: 8)
                    
                    Text(viewModel.appStatus.displayText)
                        .font(.subheadline)
                        .foregroundColor(viewModel.appStatus.color)
                }
            }
            
            Spacer()
            
            // Emergency Stop Indicator
            if hotkeyManager.emergencyStopActivated {
                Label("STOP", systemImage: "stop.fill")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    @ViewBuilder
    private var mainControlButton: some View {
        if viewModel.isRunning || viewModel.isPaused {
            // Running state: Show Pause and Stop buttons
            HStack(spacing: 12) {
                Button(action: {
                    if viewModel.canPause {
                        viewModel.pauseAutomation()
                    } else if viewModel.canResume {
                        viewModel.resumeAutomation()
                    }
                }) {
                    Label(viewModel.isPaused ? "Resume" : "Pause", 
                          systemImage: viewModel.isPaused ? "play.fill" : "pause.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity, minHeight: 36)
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.canPause && !viewModel.canResume)
                .tint(viewModel.isPaused ? .green : .orange)
                
                Button(action: {
                    viewModel.stopAutomation()
                }) {
                    Label("Stop", systemImage: "stop.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity, minHeight: 36)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
        } else {
            // Ready state: Show large start button
            Button(action: {
                viewModel.startAutomation()
            }) {
                Label("Start Automation", systemImage: "play.fill")
                    .font(.headline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canStartAutomation)
            .tint(.green)
        }
    }
    
    @ViewBuilder
    private var emergencyStopInfo: some View {
        HStack(spacing: 12) {
            // Emergency icon and primary key
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.red)

                Text("⇧⌘1")
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.black)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.red)
                    .cornerRadius(6)

                Text("EMERGENCY STOP")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }

            Spacer()

            // Alternative keys in compact format
            HStack(spacing: 6) {
                Text("or")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    Text("ESC")
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.orange)
                        .cornerRadius(4)

                    Text("F1")
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.orange)
                        .cornerRadius(4)

                    Text("SPC")
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.orange)
                        .cornerRadius(4)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1.5)
                )
        )
    }

    @ViewBuilder
    private var statisticsRow: some View {
        HStack(spacing: 16) {
            CompactStatisticView(
                title: "Clicks",
                value: "\(viewModel.statistics?.totalClicks ?? 0)",
                icon: "cursorarrow.click"
            )
            
            VStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                
                Text(timeManager.formattedElapsedTime)
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Text("Elapsed")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(6)
            
            CompactStatisticView(
                title: "Success",
                value: viewModel.statistics?.formattedSuccessRate ?? "100.0%",
                icon: "checkmark.circle"
            )
        }
    }
}

// Compact statistic view for quick start
private struct CompactStatisticView: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.blue)

            Text(value)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(title)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(6)
    }
}

// Active Target Mode Card
private struct ActiveTargetModeCard: View {
    @EnvironmentObject private var viewModel: ClickItViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "scope")
                    .foregroundColor(.purple)
                    .font(.system(size: 14))

                Toggle("Active Target Mode", isOn: $viewModel.clickSettings.isActiveTargetMode)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .toggleStyle(.switch)
            }

            if viewModel.clickSettings.isActiveTargetMode {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.purple)
                        .font(.system(size: 10))

                    Text("Cursor becomes crosshair. Right-click to start/stop clicking at cursor position.")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.textBackgroundColor))
        )
    }
}

// MARK: - Preview

struct QuickStartTab_Previews: PreviewProvider {
    static var previews: some View {
        QuickStartTab()
            .environmentObject(ClickItViewModel())
            .frame(width: 400)
            .padding()
    }
}