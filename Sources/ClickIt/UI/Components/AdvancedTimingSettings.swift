//
//  AdvancedTimingSettings.swift
//  ClickIt
//
//  Created by ClickIt on 2025-08-06.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import SwiftUI

/// Advanced timing configuration component
struct AdvancedTimingSettings: View {
    @EnvironmentObject private var viewModel: ClickItViewModel
    @State private var isExpanded = false
    
    var body: some View {
        DisclosureGroup("Advanced Timing Options", isExpanded: $isExpanded) {
            VStack(spacing: 16) {
                // Randomization section
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "dice")
                            .foregroundColor(.purple)
                            .font(.system(size: 14))
                        
                        Text("Click Randomization")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                    }
                    
                    VStack(spacing: 8) {
                        // Enable location randomization toggle
                        HStack {
                            Toggle("Enable Location Randomization", isOn: $viewModel.randomizeLocation)
                                .toggleStyle(.switch)
                            
                            Spacer()
                        }
                        
                        if viewModel.randomizeLocation {
                            // Randomization amount slider
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Location Variance:")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(viewModel.locationVariance)) px")
                                        .font(.caption)
                                        .foregroundColor(.purple)
                                        .fontWeight(.medium)
                                }
                                
                                Slider(value: $viewModel.locationVariance, in: 0...50) {
                                    Text("Location Variance")
                                } minimumValueLabel: {
                                    Text("0")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                } maximumValueLabel: {
                                    Text("50px")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .accentColor(.purple)
                            }
                            
                            // Randomization explanation
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.purple)
                                    .font(.system(size: 12))
                                
                                Text("Varies click location by ±\(Int(viewModel.locationVariance)) pixels")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(6)
                
                // Precision timing section
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(.orange)
                            .font(.system(size: 14))
                        
                        Text("Precision Timing")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                    }
                    
                    VStack(spacing: 8) {
                        // Stop on error toggle
                        HStack {
                            Toggle("Stop on Error", isOn: $viewModel.stopOnError)
                                .toggleStyle(.switch)
                            
                            Spacer()
                        }
                        
                        // Error handling explanation
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.orange)
                                .font(.system(size: 12))
                            
                            Text("Automatically stops automation when errors occur")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(6)
                
                // Window targeting section
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "target")
                            .foregroundColor(.blue)
                            .font(.system(size: 14))
                        
                        Text("Window Targeting")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                    }
                    
                    VStack(spacing: 8) {
                        // Current click type display
                        HStack {
                            Text("Click Type:")
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text(viewModel.clickType.rawValue.capitalized)
                                .font(.caption)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                        }
                        
                        // Target point info
                        HStack {
                            Text("Target Point:")
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            if let point = viewModel.targetPoint {
                                Text("(\(Int(point.x)), \(Int(point.y)))")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .fontWeight(.medium)
                            } else {
                                Text("Not Set")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(6)
            }
            .padding(.top, 8)
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Preview

struct AdvancedTimingSettings_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedTimingSettings()
            .environmentObject(ClickItViewModel())
            .frame(width: 400)
            .padding()
    }
}