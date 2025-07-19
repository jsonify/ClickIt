//
//  ElapsedTimeManager.swift
//  ClickIt
//
//  Created by ClickIt on 2025-07-19.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import Foundation
import Combine

/// Manages real-time elapsed time tracking with continuous updates
@MainActor
class ElapsedTimeManager: ObservableObject {
    // MARK: - Published Properties
    
    /// Current elapsed time in seconds, updated continuously at 10Hz
    @Published var elapsedTime: TimeInterval = 0
    
    /// Whether time tracking is currently active
    @Published var isTracking: Bool = false
    
    // MARK: - Properties
    
    /// Shared singleton instance
    static let shared = ElapsedTimeManager()
    
    /// Timer for continuous UI updates
    private var displayTimer: Timer?
    
    /// Session start timestamp
    private var sessionStartTime: TimeInterval = 0
    
    /// Update interval for display timer (100ms = 10Hz)
    private let updateInterval: TimeInterval = 0.1
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Starts continuous elapsed time tracking
    func startTracking() {
        guard !isTracking else { return }
        
        sessionStartTime = CFAbsoluteTimeGetCurrent()
        isTracking = true
        elapsedTime = 0
        
        startDisplayTimer()
        
        print("[ElapsedTimeManager] Started tracking at \(sessionStartTime)")
    }
    
    /// Stops elapsed time tracking and resets timer
    func stopTracking() {
        guard isTracking else { return }
        
        isTracking = false
        stopDisplayTimer()
        
        let finalTime = elapsedTime
        elapsedTime = 0
        sessionStartTime = 0
        
        print("[ElapsedTimeManager] Stopped tracking, final time: \(finalTime)s")
    }
    
    /// Pauses tracking while preserving current elapsed time
    func pauseTracking() {
        guard isTracking else { return }
        
        stopDisplayTimer()
        isTracking = false
        
        print("[ElapsedTimeManager] Paused tracking at \(elapsedTime)s")
    }
    
    /// Resumes tracking from current elapsed time
    func resumeTracking() {
        guard !isTracking && sessionStartTime > 0 else { return }
        
        // Adjust session start time to account for elapsed time
        sessionStartTime = CFAbsoluteTimeGetCurrent() - elapsedTime
        isTracking = true
        
        startDisplayTimer()
        
        print("[ElapsedTimeManager] Resumed tracking from \(elapsedTime)s")
    }
    
    /// Gets current session time, works whether tracking is active or paused
    var currentSessionTime: TimeInterval {
        if isTracking && sessionStartTime > 0 {
            return CFAbsoluteTimeGetCurrent() - sessionStartTime
        } else {
            return elapsedTime
        }
    }
    
    // MARK: - Private Methods
    
    /// Starts the display timer for continuous updates
    private func startDisplayTimer() {
        stopDisplayTimer() // Ensure no duplicate timers
        
        displayTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateElapsedTime()
            }
        }
        
        // Ensure timer runs in common run loop modes for responsiveness
        if let timer = displayTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    /// Stops the display timer
    private func stopDisplayTimer() {
        displayTimer?.invalidate()
        displayTimer = nil
    }
    
    /// Updates the elapsed time from current timestamp
    private func updateElapsedTime() {
        guard isTracking && sessionStartTime > 0 else { return }
        
        let currentTime = CFAbsoluteTimeGetCurrent()
        elapsedTime = currentTime - sessionStartTime
    }
}

// MARK: - Formatting Extensions

extension ElapsedTimeManager {
    /// Formats elapsed time as MM:SS or HH:MM:SS
    var formattedElapsedTime: String {
        formatElapsedTime(currentSessionTime)
    }
    
    /// Formats a time interval as MM:SS or HH:MM:SS
    /// - Parameter time: Time interval in seconds
    /// - Returns: Formatted time string
    func formatElapsedTime(_ time: TimeInterval) -> String {
        let totalSeconds = Int(time)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Debug Support

extension ElapsedTimeManager {
    /// Debug information for troubleshooting
    var debugInfo: String {
        return """
        ElapsedTimeManager Debug Info:
        - isTracking: \(isTracking)
        - elapsedTime: \(elapsedTime)s
        - sessionStartTime: \(sessionStartTime)
        - currentSessionTime: \(currentSessionTime)s
        - formattedTime: \(formattedElapsedTime)
        - displayTimer active: \(displayTimer != nil)
        """
    }
}