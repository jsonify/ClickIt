//
//  AdvancedTab.swift
//  ClickIt
//
//  Created by ClickIt on 2025-08-06.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import SwiftUI

/// Advanced tab containing developer information and app details
struct AdvancedTab: View {
    @EnvironmentObject private var viewModel: ClickItViewModel
    @State private var showingClickTestWindow = false
    @State private var showingWindowDetectionTest = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Tab header
                HStack {
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.title2)
                        .foregroundColor(.purple)

                    Text("Advanced")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Spacer()

                    // Build info indicator
                    Text("Debug")
                        .font(.caption)
                        .foregroundColor(.purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(4)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                VStack(spacing: 12) {
                    // Developer Tools
                    DeveloperTools(
                        showingClickTestWindow: $showingClickTestWindow,
                        showingWindowDetectionTest: $showingWindowDetectionTest
                    )

                    // App information
                    AppInformation()

                    // System status
                    SystemStatus()

                    // Debug information
                    DebugInformation()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showingClickTestWindow) {
            ClickTestWindow()
        }
        .sheet(isPresented: $showingWindowDetectionTest) {
            WindowDetectionTestView()
        }
    }
}

// MARK: - Developer Tools Component

private struct DeveloperTools: View {
    @Binding var showingClickTestWindow: Bool
    @Binding var showingWindowDetectionTest: Bool
    @State private var isExpanded = true

    var body: some View {
        DisclosureGroup("Developer Tools", isExpanded: $isExpanded) {
            VStack(spacing: 12) {
                // Description
                Text("Testing utilities for validating auto-clicker functionality")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)

                // Click Test Window Button
                Button {
                    showingClickTestWindow = true
                } label: {
                    HStack {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Click Test Window")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Text("Test auto-clicker with visual targets")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(10)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)

                // Window Detection Test Button
                Button {
                    showingWindowDetectionTest = true
                } label: {
                    HStack {
                        Image(systemName: "rectangle.3.offgrid")
                            .font(.system(size: 16))
                            .foregroundColor(.green)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Window Detection Test")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Text("Test window targeting functionality")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(10)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - App Information Component

private struct AppInformation: View {
    @EnvironmentObject private var viewModel: ClickItViewModel
    @State private var isExpanded = true
    
    var body: some View {
        DisclosureGroup("Application Information", isExpanded: $isExpanded) {
            VStack(spacing: 8) {
                InfoRow(label: "App Name", value: "ClickIt")
                InfoRow(label: "Version", value: Bundle.main.appVersion ?? "Unknown")
                InfoRow(label: "Build", value: Bundle.main.appBuild ?? "Unknown")
                InfoRow(label: "Bundle ID", value: Bundle.main.bundleIdentifier ?? "Unknown")
                InfoRow(label: "Framework", value: "SwiftUI + CoreGraphics")
                InfoRow(label: "Minimum macOS", value: "macOS 15.0")
            }
            .padding(.top, 8)
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - System Status Component

private struct SystemStatus: View {
    @EnvironmentObject private var viewModel: ClickItViewModel
    @State private var isExpanded = false
    
    var body: some View {
        DisclosureGroup("System Status", isExpanded: $isExpanded) {
            VStack(spacing: 8) {
                InfoRow(label: "macOS Version", value: ProcessInfo.processInfo.operatingSystemVersionString)
                InfoRow(label: "Architecture", value: ProcessInfo.processInfo.machineType)
                InfoRow(label: "Process ID", value: "\(ProcessInfo.processInfo.processIdentifier)")
                InfoRow(label: "Memory Usage", value: "\(getMemoryUsage()) MB")
                InfoRow(label: "Launch Time", value: ProcessInfo.processInfo.processUptime.formatted())
            }
            .padding(.top, 8)
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func getMemoryUsage() -> Int {
        let task = mach_task_self_
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(task, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        return result == KERN_SUCCESS ? Int(info.phys_footprint) / 1024 / 1024 : 0
    }
}

// MARK: - Debug Information Component

private struct DebugInformation: View {
    @EnvironmentObject private var viewModel: ClickItViewModel
    @State private var isExpanded = false
    
    var body: some View {
        DisclosureGroup("Debug Information", isExpanded: $isExpanded) {
            VStack(spacing: 8) {
                InfoRow(label: "App Status", value: viewModel.appStatus.displayText)
                InfoRow(label: "Is Running", value: viewModel.isRunning ? "Yes" : "No")
                InfoRow(label: "Is Paused", value: viewModel.isPaused ? "Yes" : "No")
                InfoRow(label: "Timer Mode", value: viewModel.timerMode == .off ? "Off" : "Countdown")
                InfoRow(label: "Timer Active", value: viewModel.timerIsActive ? "Yes" : "No")
                InfoRow(label: "Emergency Stop", value: viewModel.emergencyStopEnabled ? "Enabled" : "Disabled")
                InfoRow(label: "Can Start", value: viewModel.canStartAutomation ? "Yes" : "No")
                InfoRow(label: "Target Point", value: viewModel.targetPoint != nil ? "Set (\(Int(viewModel.targetPoint?.x ?? 0)), \(Int(viewModel.targetPoint?.y ?? 0)))" : "Not Set")
            }
            .padding(.top, 8)
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Supporting Components

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
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Extensions

private extension Bundle {
    var appVersion: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    var appBuild: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
}

private extension ProcessInfo {
    var machineType: String {
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        return String(cString: machine)
    }
    
    var processUptime: TimeInterval {
        return ProcessInfo.processInfo.systemUptime
    }
}

private extension TimeInterval {
    func formatted() -> String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        let seconds = Int(self) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Preview

struct AdvancedTab_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedTab()
            .environmentObject(ClickItViewModel())
            .frame(width: 500, height: 600)
    }
}