//
//  PerformanceDashboard.swift
//  ClickIt
//
//  Created by ClickIt on 2025-07-24.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import SwiftUI

/// Real-time performance dashboard showing timing accuracy and resource usage
struct PerformanceDashboard: View {
    
    // MARK: - Properties
    
    /// Performance monitor reference
    @StateObject private var performanceMonitor = PerformanceMonitor.shared
    
    /// Performance validator reference
    private let performanceValidator = PerformanceValidator.shared
    
    /// Click coordinator for timing metrics
    private let clickCoordinator = ClickCoordinator.shared
    
    /// Current performance report
    @State private var performanceReport: PerformanceReport?
    
    /// Current timing accuracy
    @State private var timingAccuracy: TimingAccuracyStats?
    
    /// Validation results
    @State private var validationResults: ValidationResult?
    
    /// Auto-refresh toggle
    @State private var autoRefresh: Bool = true
    
    /// Refresh timer
    @State private var refreshTimer: Timer?
    
    /// Show detailed metrics
    @State private var showDetailedMetrics: Bool = false
    
    /// Show validation history
    @State private var showValidationHistory: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                performanceDashboardHeader
                
                // Performance Status Overview
                performanceStatusCard
                
                // Real-time Metrics
                realTimeMetricsGrid
                
                // Timing Accuracy Section
                timingAccuracyCard
                
                // Performance Alerts
                if let report = performanceReport, !report.activeAlerts.isEmpty {
                    performanceAlertsCard(alerts: report.activeAlerts)
                }
                
                // Performance Trends
                performanceTrendsCard
                
                // Validation Results
                if let results = validationResults {
                    validationResultsCard(results: results)
                }
                
                // Action Buttons
                actionButtonsCard
                
                // Detailed Metrics (expandable)
                if showDetailedMetrics {
                    detailedMetricsCard
                }
                
                Spacer()
            }
            .padding()
        }
        .background(Color(NSColor.controlBackgroundColor))
        .onAppear {
            startMonitoring()
        }
        .onDisappear {
            stopMonitoring()
        }
        .sheet(isPresented: $showValidationHistory) {
            ValidationHistoryView()
        }
    }
    
    // MARK: - Dashboard Header
    
    private var performanceDashboardHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Performance Dashboard")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let report = performanceReport {
                    Text("Status: \(report.performanceStatus.rawValue)")
                        .font(.caption)
                        .foregroundColor(colorForStatus(report.performanceStatus))
                }
            }
            
            Spacer()
            
            HStack {
                Toggle("Auto Refresh", isOn: $autoRefresh)
                    .onChange(of: autoRefresh) {
                        if autoRefresh {
                            startAutoRefresh()
                        } else {
                            stopAutoRefresh()
                        }
                    }
                
                Button("Refresh") {
                    refreshMetrics()
                }
                .disabled(autoRefresh)
            }
        }
    }
    
    // MARK: - Performance Status Card
    
    private var performanceStatusCard: some View {
        PerformanceCard(title: "Performance Status", systemImage: "gauge.high") {
            if let report = performanceReport {
                VStack(spacing: 12) {
                    // Overall Status
                    HStack {
                        Text("Overall Status:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(report.performanceStatus.rawValue)
                            .fontWeight(.bold)
                            .foregroundColor(colorForStatus(report.performanceStatus))
                    }
                    
                    // Quick Metrics
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Memory")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(String(format: "%.1f", report.memoryUsageMB)) MB")
                                .fontWeight(.medium)
                                .foregroundColor(report.memoryUsageMB > report.memoryTargetMB ? .red : .primary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .center) {
                            Text("CPU")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(String(format: "%.1f", report.cpuUsagePercent))%")
                                .fontWeight(.medium)
                                .foregroundColor(report.cpuUsagePercent > report.cpuTargetPercent ? .red : .primary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Target")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("<\(String(format: "%.0f", report.memoryTargetMB))MB / <\(String(format: "%.0f", report.cpuTargetPercent))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                Text("Loading performance data...")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Real-time Metrics Grid
    
    private var realTimeMetricsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            // Memory Usage Metric
            MetricCard(
                title: "Memory Usage",
                value: performanceReport?.memoryUsageMB ?? 0,
                unit: "MB",
                target: performanceReport?.memoryTargetMB ?? 50,
                trend: performanceReport?.memoryTrend.direction ?? .stable,
                color: (performanceReport?.memoryUsageMB ?? 0) > (performanceReport?.memoryTargetMB ?? 50) ? .red : .green
            )
            
            // CPU Usage Metric
            MetricCard(
                title: "CPU Usage",
                value: performanceReport?.cpuUsagePercent ?? 0,
                unit: "%",
                target: performanceReport?.cpuTargetPercent ?? 5,
                trend: performanceReport?.cpuTrend.direction ?? .stable,
                color: (performanceReport?.cpuUsagePercent ?? 0) > (performanceReport?.cpuTargetPercent ?? 5) ? .red : .green
            )
        }
    }
    
    // MARK: - Timing Accuracy Card
    
    private var timingAccuracyCard: some View {
        PerformanceCard(title: "Timing Accuracy", systemImage: "timer") {
            if let timing = timingAccuracy {
                VStack(spacing: 12) {
                    // Accuracy Overview
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Accuracy")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(String(format: "%.1f", timing.accuracyPercentage))%")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(timing.isWithinTolerance ? .green : .red)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .center) {
                            Text("Mean Error")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(String(format: "%.2f", timing.meanError * 1000))ms")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(timing.meanError <= 0.002 ? .green : .orange)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Std Dev")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(String(format: "%.2f", timing.standardDeviation * 1000))ms")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(timing.standardDeviation <= 0.003 ? .green : .orange)
                        }
                    }
                    
                    // Target Information
                    HStack {
                        Text("Target: ±10ms accuracy")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Measurements: \(timing.measurements)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                HStack {
                    Text("No active automation")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Start automation to see timing metrics")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Performance Alerts Card
    
    private func performanceAlertsCard(alerts: [PerformanceAlert]) -> some View {
        PerformanceCard(title: "Performance Alerts", systemImage: "exclamationmark.triangle") {
            VStack(spacing: 8) {
                ForEach(alerts, id: \.id) { alert in
                    HStack(alignment: .top) {
                        Image(systemName: iconForAlertSeverity(alert.severity))
                            .foregroundColor(colorForAlertSeverity(alert.severity))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(alert.message)
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Text(alert.recommendation)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    
                    if alert != alerts.last {
                        Divider()
                    }
                }
            }
        }
    }
    
    // MARK: - Performance Trends Card
    
    private var performanceTrendsCard: some View {
        PerformanceCard(title: "Performance Trends", systemImage: "chart.line.uptrend.xyaxis") {
            if let report = performanceReport {
                VStack(spacing: 12) {
                    // Memory Trend
                    HStack {
                        Text("Memory:")
                            .fontWeight(.medium)
                        Spacer()
                        trendIndicator(direction: report.memoryTrend.direction)
                        Text(trendDescription(report.memoryTrend.direction))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // CPU Trend
                    HStack {
                        Text("CPU:")
                            .fontWeight(.medium)
                        Spacer()
                        trendIndicator(direction: report.cpuTrend.direction)
                        Text(trendDescription(report.cpuTrend.direction))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Validation Results Card
    
    private func validationResultsCard(results: ValidationResult) -> some View {
        PerformanceCard(title: "Validation Results", systemImage: "checkmark.seal") {
            VStack(spacing: 12) {
                // Overall Result
                HStack {
                    Text("Overall:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(results.overallPassed ? "✅ PASSED" : "❌ FAILED")
                        .fontWeight(.bold)
                        .foregroundColor(results.overallPassed ? .green : .red)
                }
                
                // Success Rate
                HStack {
                    Text("Success Rate:")
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(results.passedTests)/\(results.totalTests) (\(String(format: "%.1f", results.successRate))%)")
                        .foregroundColor(results.successRate >= 90 ? .green : .orange)
                }
                
                // Duration
                HStack {
                    Text("Duration:")
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(String(format: "%.2f", results.validationDuration))s")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Action Buttons Card
    
    private var actionButtonsCard: some View {
        PerformanceCard(title: "Actions", systemImage: "gearshape.2") {
            VStack(spacing: 12) {
                HStack {
                    Button("Run Validation") {
                        runPerformanceValidation()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Spacer()
                    
                    Button("Optimize") {
                        optimizePerformance()
                    }
                    .buttonStyle(.bordered)
                }
                
                HStack {
                    Button("View History") {
                        showValidationHistory = true
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button(showDetailedMetrics ? "Hide Details" : "Show Details") {
                        showDetailedMetrics.toggle()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
    
    // MARK: - Detailed Metrics Card
    
    private var detailedMetricsCard: some View {
        PerformanceCard(title: "Detailed Metrics", systemImage: "list.bullet") {
            if let report = performanceReport {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommendations:")
                        .fontWeight(.medium)
                    
                    ForEach(report.recommendations, id: \.self) { recommendation in
                        Text("• \(recommendation)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let timing = timingAccuracy {
                        Divider()
                        
                        Text("Timing Details:")
                            .fontWeight(.medium)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Target Interval: \(String(format: "%.1f", timing.targetInterval * 1000))ms")
                                Text("Max Error: \(String(format: "%.2f", timing.maxError * 1000))ms")
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Within Tolerance: \(timing.isWithinTolerance ? "Yes" : "No")")
                                Text("Measurements: \(timing.measurements)")
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func startMonitoring() {
        performanceMonitor.startMonitoring()
        refreshMetrics()
        
        if autoRefresh {
            startAutoRefresh()
        }
    }
    
    private func stopMonitoring() {
        stopAutoRefresh()
    }
    
    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            refreshMetrics()
        }
    }
    
    private func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func refreshMetrics() {
        performanceReport = performanceMonitor.getPerformanceReport()
        timingAccuracy = clickCoordinator.getTimingAccuracy()
    }
    
    private func runPerformanceValidation() {
        Task {
            let results = await performanceValidator.validatePerformance()
            await MainActor.run {
                validationResults = results
            }
        }
    }
    
    private func optimizePerformance() {
        clickCoordinator.optimizePerformance()
        
        // Refresh metrics after optimization
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            refreshMetrics()
        }
    }
    
    // MARK: - UI Helper Methods
    
    private func colorForStatus(_ status: PerformanceStatus) -> Color {
        switch status {
        case .optimal: return .green
        case .good: return .blue
        case .warning: return .orange
        case .critical: return .red
        }
    }
    
    private func colorForAlertSeverity(_ severity: PerformanceAlert.Severity) -> Color {
        switch severity {
        case .info: return .blue
        case .warning: return .orange
        case .critical: return .red
        }
    }
    
    private func iconForAlertSeverity(_ severity: PerformanceAlert.Severity) -> String {
        switch severity {
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        case .critical: return "xmark.octagon"
        }
    }
    
    private func trendIndicator(direction: TrendDirection) -> some View {
        Image(systemName: {
            switch direction {
            case .increasing: return "arrow.up"
            case .decreasing: return "arrow.down"
            case .stable: return "arrow.left.and.right"
            }
        }())
        .foregroundColor({
            switch direction {
            case .increasing: return .red
            case .decreasing: return .green
            case .stable: return .gray
            }
        }())
    }
    
    private func trendDescription(_ direction: TrendDirection) -> String {
        switch direction {
        case .increasing: return "Increasing"
        case .decreasing: return "Decreasing"
        case .stable: return "Stable"
        }
    }
}

// MARK: - Metric Card Component

struct MetricCard: View {
    let title: String
    let value: Double
    let unit: String
    let target: Double
    let trend: TrendDirection
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                trendIcon
            }
            
            HStack(alignment: .bottom, spacing: 4) {
                Text(String(format: "%.1f", value))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            Text("Target: <\(String(format: "%.0f", target))\(unit)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var trendIcon: some View {
        Image(systemName: {
            switch trend {
            case .increasing: return "arrow.up.circle.fill"
            case .decreasing: return "arrow.down.circle.fill"
            case .stable: return "minus.circle.fill"
            }
        }())
        .foregroundColor({
            switch trend {
            case .increasing: return .red
            case .decreasing: return .green
            case .stable: return .gray
            }
        }())
        .font(.caption)
    }
}

// MARK: - Validation History View

struct ValidationHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var validationHistory: [ValidationResult] = []
    
    private let performanceValidator = PerformanceValidator.shared
    
    var body: some View {
        NavigationView {
            List(validationHistory, id: \.timestamp) { result in
                ValidationHistoryRow(result: result)
            }
            .navigationTitle("Validation History")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Refresh") {
                        loadHistory()
                    }
                }
            }
        }
        .onAppear {
            loadHistory()
        }
    }
    
    private func loadHistory() {
        validationHistory = performanceValidator.getValidationHistory()
    }
}

struct ValidationHistoryRow: View {
    let result: ValidationResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(result.overallPassed ? "✅" : "❌")
                Text("\(result.passedTests)/\(result.totalTests) tests passed")
                    .fontWeight(.medium)
                Spacer()
                Text(DateFormatter.localizedString(from: result.timestamp, dateStyle: .none, timeStyle: .medium))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("Duration: \(String(format: "%.2f", result.validationDuration))s")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Performance Card Component

struct PerformanceCard<Content: View>: View {
    let title: String
    let systemImage: String
    let content: Content
    
    init(title: String, systemImage: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            // Content
            content
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
    }
}