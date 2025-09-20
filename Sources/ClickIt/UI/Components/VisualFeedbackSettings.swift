//
//  VisualFeedbackSettings.swift
//  ClickIt
//
//  Created by ClickIt on 2025-08-06.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import SwiftUI

/// Visual and audio feedback settings component
struct VisualFeedbackSettings: View {
    @EnvironmentObject private var viewModel: ClickItViewModel
    @State private var isExpanded = true
    
    var body: some View {
        DisclosureGroup("Visual & Audio Feedback", isExpanded: $isExpanded) {
            VStack(spacing: 16) {
                // Visual feedback section
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "eye")
                            .foregroundColor(.blue)
                            .font(.system(size: 14))
                        
                        Text("Visual Feedback")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                    }
                    
                    VStack(spacing: 8) {
                        // Show visual feedback toggle
                        HStack {
                            Toggle("Show Click Overlay", isOn: $viewModel.showVisualFeedback)
                                .toggleStyle(.switch)
                            
                            Spacer()
                        }
                        
                        // Description
                        if viewModel.showVisualFeedback {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 12))
                                
                                Text("Displays floating indicators at click locations")
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
                
                // Audio feedback section  
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "speaker.wave.2")
                            .foregroundColor(.orange)
                            .font(.system(size: 14))
                        
                        Text("Audio Feedback")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                    }
                    
                    VStack(spacing: 8) {
                        // Play sound feedback toggle
                        HStack {
                            Toggle("Play Click Sound", isOn: $viewModel.playSoundFeedback)
                                .toggleStyle(.switch)
                            
                            Spacer()
                        }
                        
                        // Description and volume warning
                        VStack(alignment: .leading, spacing: 4) {
                            if viewModel.playSoundFeedback {
                                HStack {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 12))
                                    
                                    Text("Plays system sound for each click")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                }
                                
                                HStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 12))
                                    
                                    Text("Warning: Can be loud with high CPS rates")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(6)
                
                // Performance note
                VStack(spacing: 4) {
                    HStack {
                        Image(systemName: "speedometer")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                        
                        Text("Performance Impact")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    
                    Text("Disabling feedback can improve performance at very high CPS rates (>50)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(.top, 8)
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Preview

struct VisualFeedbackSettings_Previews: PreviewProvider {
    static var previews: some View {
        VisualFeedbackSettings()
            .environmentObject(ClickItViewModel())
            .frame(width: 400)
            .padding()
    }
}