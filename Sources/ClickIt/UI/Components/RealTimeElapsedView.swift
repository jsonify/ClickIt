//
//  RealTimeElapsedView.swift
//  ClickIt
//
//  Created by ClickIt on 2025-07-19.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import SwiftUI

/// A view that displays continuously updating elapsed time
struct RealTimeElapsedView: View {
    @ObservedObject var timeManager: ElapsedTimeManager
    
    var body: some View {
        Text(timeManager.formattedElapsedTime)
            .font(.system(.title3, design: .monospaced))
            .fontWeight(.semibold)
            .foregroundColor(timeManager.isTracking ? .primary : .secondary)
            .animation(.none, value: timeManager.elapsedTime) // Prevent animation flicker
    }
}

/// A view that displays elapsed time in statistic card format
struct ElapsedTimeStatisticView: View {
    @ObservedObject var timeManager: ElapsedTimeManager
    let fallbackStatistics: SessionStatistics?
    
    var body: some View {
        StatisticView(
            title: "Elapsed",
            value: displayValue,
            icon: "clock"
        )
    }
    
    private var displayValue: String {
        if timeManager.isTracking {
            return timeManager.formattedElapsedTime
        } else if let stats = fallbackStatistics {
            return stats.formattedDuration
        } else {
            return "00:00"
        }
    }
}

struct RealTimeElapsedView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Text("Real-Time Elapsed Time Display")
                .font(.headline)
            
            RealTimeElapsedView(timeManager: {
                let manager = ElapsedTimeManager.shared
                manager.startTracking()
                return manager
            }())
            
            Button("Start/Stop Tracking") {
                let manager = ElapsedTimeManager.shared
                if manager.isTracking {
                    manager.stopTracking()
                } else {
                    manager.startTracking()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(width: 300)
        .previewDisplayName("Real Time Elapsed View")
        
        ElapsedTimeStatisticView(
            timeManager: ElapsedTimeManager.shared,
            fallbackStatistics: SessionStatistics(
                duration: 125,
                totalClicks: 50,
                successfulClicks: 48,
                failedClicks: 2,
                successRate: 0.96,
                averageClickTime: 0.05,
                clicksPerSecond: 2.4,
                isActive: false
            )
        )
        .frame(width: 120, height: 100)
        .padding()
        .previewDisplayName("Elapsed Time Statistic")
    }
}