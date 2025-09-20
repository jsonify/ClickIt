//
//  StatisticsTab.swift
//  ClickIt
//
//  Created by ClickIt on 2025-08-06.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import SwiftUI

/// Statistics tab showing basic performance and session information
struct StatisticsTab: View {
    @EnvironmentObject private var viewModel: ClickItViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Tab header
                HStack {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text("Statistics")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // Status indicator
                    if viewModel.isRunning {
                        Label("ACTIVE", systemImage: "dot.radiowaves.left.and.right")
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                VStack(spacing: 12) {
                    // Current session information
                    CurrentSessionCard()
                    
                    // Configuration summary
                    ConfigurationSummary()
                    
                    // Statistics information
                    StatisticsInformation()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Current Session Component

private struct CurrentSessionCard: View {
    @EnvironmentObject private var viewModel: ClickItViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "timer")
                    .foregroundColor(.green)
                    .font(.system(size: 14))
                
                Text("Current Session")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(viewModel.appStatus.displayText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                // App status
                StatCard(
                    title: "Status",
                    value: viewModel.appStatus.displayText,
                    color: viewModel.isRunning ? .green : .blue
                )
                
                // Duration mode
                StatCard(
                    title: "Duration Mode",
                    value: viewModel.durationMode.displayName,
                    color: .purple
                )
                
                // Estimated CPS
                StatCard(
                    title: "Est. CPS",
                    value: String(format: "%.1f", viewModel.estimatedCPS),
                    color: .orange
                )
                
                // Click type
                StatCard(
                    title: "Click Type",
                    value: viewModel.clickType.rawValue.capitalized,
                    color: .blue
                )
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Configuration Summary Component

private struct ConfigurationSummary: View {
    @EnvironmentObject private var viewModel: ClickItViewModel
    @State private var isExpanded = false
    
    var body: some View {
        DisclosureGroup("Configuration Summary", isExpanded: $isExpanded) {
            VStack(spacing: 8) {
                InfoRow(label: "Interval", value: "\(viewModel.totalMilliseconds)ms")
                InfoRow(label: "Target Point", value: viewModel.targetPoint != nil ? "Set" : "Not Set")
                InfoRow(label: "Randomize Location", value: viewModel.randomizeLocation ? "Yes" : "No")
                InfoRow(label: "Location Variance", value: "\(Int(viewModel.locationVariance))px")
                InfoRow(label: "Visual Feedback", value: viewModel.showVisualFeedback ? "On" : "Off")
                InfoRow(label: "Sound Feedback", value: viewModel.playSoundFeedback ? "On" : "Off")
                InfoRow(label: "Stop on Error", value: viewModel.stopOnError ? "Yes" : "No")
                InfoRow(label: "Emergency Stop", value: viewModel.emergencyStopEnabled ? "Enabled" : "Disabled")
            }
            .padding(.top, 8)
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Statistics Information Component

private struct StatisticsInformation: View {
    @EnvironmentObject private var viewModel: ClickItViewModel
    @State private var isExpanded = false
    
    var body: some View {
        DisclosureGroup("Session Statistics", isExpanded: $isExpanded) {
            VStack(spacing: 12) {
                if let stats = viewModel.statistics {
                    VStack(spacing: 8) {
                        InfoRow(label: "Total Clicks", value: "\(stats.totalClicks)")
                        InfoRow(label: "Success Rate", value: String(format: "%.1f%%", stats.successRate * 100))
                        InfoRow(label: "Duration", value: String(format: "%.1fs", stats.duration))
                        InfoRow(label: "Failed Clicks", value: "\(stats.failedClicks)")
                    }
                } else {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                        
                        Text("No session statistics available yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .padding(.vertical, 20)
                }
            }
            .padding(.top, 8)
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Supporting Components

private struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(6)
    }
}

private struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Preview

struct StatisticsTab_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsTab()
            .environmentObject(ClickItViewModel())
            .frame(width: 500, height: 600)
    }
}