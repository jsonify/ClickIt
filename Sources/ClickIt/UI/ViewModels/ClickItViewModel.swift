//
//  ClickItViewModel.swift
//  ClickIt
//
//  Created by ClickIt on 2025-07-13.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import SwiftUI
import CoreGraphics
import Combine

@MainActor
class ClickItViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var targetPoint: CGPoint?
    @Published var isRunning = false
    @Published var appStatus: AppStatus = .ready
    
    // Configuration Properties
    @Published var intervalHours = 0
    @Published var intervalMinutes = 0
    @Published var intervalSeconds = 1
    @Published var intervalMilliseconds = 0
    
    @Published var clickType: ClickType = .left
    @Published var durationMode: DurationMode = .unlimited
    @Published var durationSeconds: Double = 60
    @Published var maxClicks = 100
    
    // Advanced Settings
    @Published var randomizeLocation = false
    @Published var locationVariance: Double = 0
    @Published var stopOnError = true
    @Published var showVisualFeedback = true
    @Published var playSoundFeedback = false
    
    // Statistics
    @Published var statistics: SessionStatistics?
    
    // MARK: - Computed Properties
    var totalMilliseconds: Int {
        return (intervalHours * 3600 + intervalMinutes * 60 + intervalSeconds) * 1000 + intervalMilliseconds
    }
    
    var estimatedCPS: Double {
        guard totalMilliseconds > 0 else { return 0.0 }
        return 1000.0 / Double(totalMilliseconds)
    }
    
    var canStartAutomation: Bool {
        return targetPoint != nil && totalMilliseconds > 0 && !isRunning
    }
    
    // MARK: - Dependencies
    private let clickCoordinator = ClickCoordinator.shared
    
    // MARK: - Initialization
    init() {
        setupBindings()
    }
    
    // MARK: - Public Methods
    func setTargetPoint(_ point: CGPoint) {
        targetPoint = point
    }
    
    func startAutomation() {
        guard let point = targetPoint, canStartAutomation else { return }
        
        let config = AutomationConfiguration(
            location: point,
            clickType: clickType,
            clickInterval: Double(totalMilliseconds) / 1000.0,
            targetApplication: nil,
            maxClicks: durationMode == .clickCount ? maxClicks : nil,
            maxDuration: durationMode == .timeLimit ? durationSeconds : nil,
            stopOnError: stopOnError,
            randomizeLocation: randomizeLocation,
            locationVariance: CGFloat(randomizeLocation ? locationVariance : 0),
            showVisualFeedback: showVisualFeedback
        )
        
        clickCoordinator.startAutomation(with: config)
        isRunning = true
        appStatus = .running
    }
    
    func stopAutomation() {
        clickCoordinator.stopAutomation()
        isRunning = false
        appStatus = .ready
    }
    
    func resetConfiguration() {
        intervalHours = 0
        intervalMinutes = 0
        intervalSeconds = 1
        intervalMilliseconds = 0
        clickType = .left
        durationMode = .unlimited
        durationSeconds = 60
        maxClicks = 100
        randomizeLocation = false
        locationVariance = 0
        stopOnError = true
        showVisualFeedback = true
        playSoundFeedback = false
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Monitor click coordinator state
        clickCoordinator.objectWillChange.sink { [weak self] in
            self?.updateStatistics()
        }
        .store(in: &cancellables)
    }
    
    private func updateStatistics() {
        statistics = clickCoordinator.getSessionStatistics()
    }
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
}

// MARK: - SessionStatistics Extensions
extension SessionStatistics {
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var formattedSuccessRate: String {
        return String(format: "%.1f%%", successRate * 100)
    }
}

// MARK: - Supporting Types
enum AppStatus {
    case ready
    case running
    case error(String)
    
    var displayText: String {
        switch self {
        case .ready:
            return "Ready"
        case .running:
            return "Running"
        case .error(let message):
            return "Error: \(message)"
        }
    }
    
    var color: Color {
        switch self {
        case .ready:
            return .green
        case .running:
            return .blue
        case .error:
            return .red
        }
    }
}

