//
//  SimpleViewModel.swift
//  ClickIt Lite
//
//  Simple view model for ClickIt Lite.
//

import Foundation
import SwiftUI

/// Simple view model for ClickIt Lite
@MainActor
final class SimpleViewModel: ObservableObject {

    // MARK: - Types

    /// Coordinate mode for clicking
    enum CoordinateMode {
        case screenCoordinates  // Static position
        case liveMouse          // Follow cursor
    }

    // MARK: - Published Properties

    @Published var clickLocation: CGPoint = CGPoint(x: 500, y: 300)
    @Published var clickInterval: Double = 1.0 // seconds
    @Published var clickType: SimpleClickEngine.ClickType = .left
    @Published var isRunning = false
    @Published var clickCount = 0
    @Published var statusMessage = "Stopped"
    @Published var coordinateMode: CoordinateMode = .screenCoordinates

    // MARK: - Private Properties

    private let clickEngine = SimpleClickEngine()
    private let hotkeyManager = SimpleHotkeyManager.shared
    private let permissionManager = SimplePermissionManager.shared

    // MARK: - Initialization

    init() {
        // Set up emergency stop handler (already on MainActor)
        hotkeyManager.startMonitoring { [weak self] in
            self?.stopClicking()
        }
    }

    deinit {
        hotkeyManager.stopMouseMonitoring()
    }

    // MARK: - Public Methods

    /// Set coordinate mode
    func setCoordinateMode(_ mode: CoordinateMode) {
        coordinateMode = mode

        // Set up or tear down mouse monitoring based on mode
        switch mode {
        case .screenCoordinates:
            hotkeyManager.stopMouseMonitoring()
            statusMessage = "Screen Coordinates Mode"
        case .liveMouse:
            hotkeyManager.startMouseMonitoring { [weak self] in
                self?.startClicking()
            }
            statusMessage = "Live Mouse Mode - Right-click to trigger"
        }
    }

    /// Start clicking
    func startClicking() {
        // Check permissions first
        guard permissionManager.hasAccessibilityPermission else {
            statusMessage = "Accessibility permission required"
            return
        }

        isRunning = true
        clickCount = 0
        statusMessage = "Running: 0 clicks"

        // Use appropriate point provider based on mode
        let pointProvider: () -> CGPoint
        switch coordinateMode {
        case .screenCoordinates:
            pointProvider = { [weak self] in
                self?.clickLocation ?? CGPoint(x: 500, y: 300)
            }
        case .liveMouse:
            pointProvider = {
                NSEvent.mouseLocation.asCGPoint()
            }
        }

        clickEngine.startClicking(
            pointProvider: pointProvider,
            interval: clickInterval,
            clickType: clickType
        ) { [weak self] count in
            // Already on MainActor, no need to wrap
            self?.clickCount = count
            self?.statusMessage = "Running: \(count) clicks"
        }
    }

    /// Stop clicking
    func stopClicking() {
        isRunning = false
        clickEngine.stopClicking()
        statusMessage = "Stopped"
    }

    /// Set click location from mouse position
    func setClickLocationFromMouse() {
        let mouseLocation = NSEvent.mouseLocation.asCGPoint()
        clickLocation = mouseLocation
    }

    /// Update click location
    func updateClickLocation(x: Double, y: Double) {
        clickLocation = CGPoint(x: x, y: y)
    }
}

// MARK: - NSPoint Extension

private extension NSPoint {
    func asCGPoint() -> CGPoint {
        // Convert from AppKit coordinates (bottom-left origin) to CG coordinates (top-left origin).
        // This must account for the entire virtual screen space in multi-monitor setups.

        // The total height of the virtual screen space is the max Y coordinate across all screens.
        // The conversion is then to subtract the AppKit Y from this total height.
        if let globalMaxY = NSScreen.screens.map({ $0.frame.maxY }).max() {
            return CGPoint(x: x, y: globalMaxY - y)
        }

        // As a fallback, use the main screen's height, which works for single-monitor setups.
        if let mainScreen = NSScreen.main {
            let screenHeight = mainScreen.frame.height
            return CGPoint(x: x, y: screenHeight - y)
        }

        // Ultimate fallback if no screen information is available.
        return CGPoint(x: x, y: y)
    }
}
