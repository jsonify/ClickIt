// swiftlint:disable file_header
//
//  StatisticsView.swift
//  ClickIt
//
//  Created by ClickIt on July 13, 2025.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import SwiftUI

/// View for displaying automation session statistics
struct StatisticsView: View {
    @EnvironmentObject private var clickCoordinator: ClickCoordinator

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.green)
                Text("Session Statistics")
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
            }

            HStack(spacing: 16) {
                statisticItem("Clicks", value: "\(clickCoordinator.clickCount)")
                statisticItem("Elapsed", value: formatElapsedTime(clickCoordinator.elapsedTime))
                statisticItem("Success Rate", value: "\(Int(clickCoordinator.successRate * 100))%")
            }
        }
        .padding(10)
        .background(Color.green.opacity(0.1))
        .cornerRadius(6)
    }

    @ViewBuilder
    private func statisticItem(_ label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.semibold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private func formatElapsedTime(_ elapsed: TimeInterval) -> String {
        let totalSeconds = Int(elapsed)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

#Preview {
    StatisticsView()
        .environmentObject(ClickCoordinator.shared)
        .frame(width: 300, height: 100)
}
