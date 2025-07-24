//
//  RandomizationSettings.swift
//  ClickIt
//
//  Created by ClickIt on 2025-07-24.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import SwiftUI

/// Settings panel for CPS timing randomization configuration
struct RandomizationSettings: View {
    @ObservedObject var clickSettings: ClickSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "waveform.path")
                    .foregroundColor(.blue)
                Text("CPS Randomization")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Overall enable/disable toggle
                Toggle("", isOn: $clickSettings.randomizeTiming)
                    .toggleStyle(SwitchToggleStyle())
            }
            
            if clickSettings.randomizeTiming {
                Divider()
                
                // Variance Configuration
                VStack(alignment: .leading, spacing: 12) {
                    Label("Timing Variance", systemImage: "slider.horizontal.3")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("Amount:")
                                .frame(width: 80, alignment: .leading)
                            
                            Slider(
                                value: $clickSettings.timingVariancePercentage,
                                in: 0.0...1.0,
                                step: 0.01
                            )
                            
                            Text("\(Int(clickSettings.timingVariancePercentage * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 35, alignment: .trailing)
                        }
                        
                        Text("Higher values create more unpredictable timing patterns")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                // Distribution Pattern
                VStack(alignment: .leading, spacing: 12) {
                    Label("Distribution Pattern", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    VStack(spacing: 8) {
                        Picker("Distribution Pattern", selection: $clickSettings.distributionPattern) {
                            ForEach(CPSRandomizer.DistributionPattern.allCases, id: \.self) { pattern in
                                Text(pattern.displayName)
                                    .tag(pattern)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        Text(clickSettings.distributionPattern.description)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                // Humanness Level
                VStack(alignment: .leading, spacing: 12) {
                    Label("Human-like Behavior", systemImage: "person.circle")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    VStack(spacing: 8) {
                        Picker("Humanness Level", selection: $clickSettings.humannessLevel) {
                            ForEach(CPSRandomizer.HumannessLevel.allCases, id: \.self) { level in
                                Text(level.displayName)
                                    .tag(level)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        Text(humannesDescription)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                // Preview Section
                VStack(alignment: .leading, spacing: 12) {
                    Label("Preview", systemImage: "eye")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    RandomizationPreview(clickSettings: clickSettings)
                }
            } else {
                // Disabled state explanation
                VStack(alignment: .leading, spacing: 8) {
                    Text("Timing randomization is disabled")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                    
                    Text("Enable to add human-like timing variation and avoid detection patterns")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    /// Description text for current humanness level
    private var humannesDescription: String {
        switch clickSettings.humannessLevel {
        case .none:
            return "Robotic timing with minimal variation"
        case .low:
            return "Slight timing variation, mostly consistent"
        case .medium:
            return "Moderate variation, balanced automation"
        case .high:
            return "Significant variation, more human-like"
        case .extreme:
            return "Maximum variation, very natural patterns"
        }
    }
}

/// Preview component showing randomization effects
struct RandomizationPreview: View {
    @ObservedObject var clickSettings: ClickSettings
    @State private var previewIntervals: [TimeInterval] = []
    @State private var isGenerating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Sample Intervals (last 10)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Generate") {
                    generatePreviewIntervals()
                }
                .font(.caption)
                .disabled(isGenerating)
            }
            
            if !previewIntervals.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(0..<previewIntervals.count, id: \.self) { index in
                            VStack(spacing: 2) {
                                Text("\(Int(previewIntervals[index] * 1000))")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                Text("ms")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 35)
                            .padding(.vertical, 4)
                            .background(Color(.quaternaryLabelColor))
                            .cornerRadius(4)
                        }
                    }
                    .padding(.horizontal, 2)
                }
                .frame(height: 35)
                
                // Statistics
                if previewIntervals.count > 1 {
                    HStack {
                        let mean = previewIntervals.reduce(0, +) / Double(previewIntervals.count)
                        let variance = previewIntervals.map { pow($0 - mean, 2) }.reduce(0, +) / Double(previewIntervals.count)
                        let stdDev = sqrt(variance)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Mean: \(Int(mean * 1000))ms")
                                .font(.caption2)
                            Text("Std Dev: ±\(Int(stdDev * 1000))ms")
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
            } else {
                Text("Click 'Generate' to preview timing patterns")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .onAppear {
            generatePreviewIntervals()
        }
    }
    
    private func generatePreviewIntervals() {
        isGenerating = true
        
        Task { @MainActor in
            let config = clickSettings.createCPSRandomizerConfiguration()
            let randomizer = CPSRandomizer(configuration: config)
            let baseInterval = clickSettings.clickIntervalSeconds
            
            var intervals: [TimeInterval] = []
            for _ in 0..<10 {
                let randomizedInterval = randomizer.randomizeInterval(baseInterval)
                intervals.append(randomizedInterval)
            }
            
            self.previewIntervals = intervals
            self.isGenerating = false
        }
    }
}

// MARK: - Preview Provider

struct RandomizationSettings_Previews: PreviewProvider {
    static var previews: some View {
        RandomizationSettings(clickSettings: ClickSettings())
            .frame(width: 400)
            .padding()
    }
}