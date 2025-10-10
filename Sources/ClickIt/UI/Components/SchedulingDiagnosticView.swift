//
//  SchedulingDiagnosticView.swift
//  ClickIt
//
//  Created by ClickIt on 2025-10-09.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import SwiftUI

/// Diagnostic view to show scheduling timing information without console logs
struct SchedulingDiagnosticView: View {
    @EnvironmentObject private var viewModel: ClickItViewModel
    @State private var currentTime = Date()
    @State private var timer: Timer?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Scheduling Diagnostics")
                .font(.headline)
                .foregroundColor(.orange)

            Divider()

            // Current time
            HStack {
                Text("Current Time:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(formatTime(currentTime))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.primary)
            }

            // Scheduled time
            HStack {
                Text("Scheduled For:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(formatTime(viewModel.clickSettings.scheduledDateTime))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.blue)
            }

            // Time difference
            HStack {
                Text("Time Until:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(formatDifference(viewModel.clickSettings.scheduledDateTime.timeIntervalSince(currentTime)))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(viewModel.clickSettings.scheduledDateTime > currentTime ? .green : .red)
            }

            // Validation status
            HStack {
                Text("Valid:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(viewModel.clickSettings.isScheduledTimeValid ? "✅ Yes" : "❌ No")
                    .font(.caption)
                    .foregroundColor(viewModel.clickSettings.isScheduledTimeValid ? .green : .red)
            }

            // Time components
            VStack(alignment: .leading, spacing: 4) {
                Text("Raw Values:")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text("Scheduled: \(viewModel.clickSettings.scheduledDateTime.timeIntervalSince1970)")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.secondary)

                Text("Current: \(currentTime.timeIntervalSince1970)")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.secondary)

                Text("Difference: \(viewModel.clickSettings.scheduledDateTime.timeIntervalSince1970 - currentTime.timeIntervalSince1970) seconds")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            currentTime = Date()
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.timeZone = TimeZoneHelper.pacificTimeZone
        return formatter.string(from: date)
    }

    private func formatDifference(_ interval: TimeInterval) -> String {
        let absInterval = abs(interval)
        let minutes = Int(absInterval) / 60
        let seconds = Int(absInterval) % 60
        let prefix = interval < 0 ? "-" : "+"
        return String(format: "%@%02d:%02d", prefix, minutes, seconds)
    }
}
