
//
//  TimingSettings.swift
//  ClickIt
//
//  Created by Jefry on 12/07/25.
//

import SwiftUI

struct TimingSettings: View {
    @ObservedObject
    var viewModel: ClickItViewModel

    var body: some View {
        VStack(spacing: 20) {
            SettingCard(
                title: "Duration Control",
                description: "Configure how long the automation should run"
            ) {
                VStack(spacing: 12) {
                    Picker("Duration Mode", selection: $viewModel.durationMode) {
                        ForEach(DurationMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    switch viewModel.durationMode {
                    case .unlimited:
                        HStack {
                            Image(systemName: "infinity")
                                .foregroundColor(.blue)
                            Text("Automation will run indefinitely until manually stopped")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)

                    case .timeLimit:
                        VStack(spacing: 8) {
                            HStack {
                                Text("Time Limit")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Spacer()
                                Text(formatDuration(viewModel.durationSeconds))
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }

                            Slider(
                                value: $viewModel.durationSeconds,
                                in: 1 ... 3600,
                                step: 1
                            ) {
                                Text("Duration")
                            } minimumValueLabel: {
                                Text("1s")
                                    .font(.caption2)
                            } maximumValueLabel: {
                                Text("1h")
                                    .font(.caption2)
                            }

                            Text("Automation will stop after \(formatDuration(viewModel.durationSeconds))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }

                    case .clickCount:
                        VStack(spacing: 8) {
                            HStack {
                                Text("Maximum Clicks:")
                                    .font(.caption)
                                    .fontWeight(.medium)

                                Spacer()

                                TextField("Count", value: $viewModel.maxClicks, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 100)
                                    .multilineTextAlignment(.trailing)
                            }

                            Text("Automation will stop after \(viewModel.maxClicks) clicks")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                    }
                }
            }

            SettingCard(
                title: "Timing Information",
                description: "Current timing configuration and performance estimates"
            ) {
                VStack(spacing: 12) {
                    HStack {
                        Text("Total Interval:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text(formatTotalTime(viewModel.totalMilliseconds))
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(.blue)
                    }

                    HStack {
                        Text("Estimated CPS:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text(String(format: "%.2f", viewModel.estimatedCPS))
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(.green)
                    }

                    if viewModel.durationMode == .timeLimit {
                        HStack {
                            Text("Expected Clicks:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(Int(viewModel.durationSeconds * viewModel.estimatedCPS))")
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
        }
    }

    private func formatDuration(_ duration: Double) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60

        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
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
