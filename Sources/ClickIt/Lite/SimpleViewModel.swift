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

    // MARK: - Published Properties

    @Published var clickLocation: CGPoint = CGPoint(x: 500, y: 300)
    @Published var clickInterval: Double = 1.0 // seconds
    @Published var clickType: SimpleClickEngine.ClickType = .left
    @Published var isRunning = false
    @Published var clickCount = 0
    @Published var statusMessage = "Stopped"

    // MARK: - Private Properties

    private let clickEngine = SimpleClickEngine()
    private let hotkeyManager = SimpleHotkeyManager.shared
    private let permissionManager = SimplePermissionManager.shared

    // MARK: - Initialization

    init() {
        // Set up emergency stop handler
        hotkeyManager.startMonitoring { [weak self] in
            Task { @MainActor in
                self?.stopClicking()
            }
        }
    }

    // MARK: - Public Methods

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

        clickEngine.startClicking(
            at: clickLocation,
            interval: clickInterval,
            clickType: clickType
        ) { [weak self] count in
            Task { @MainActor in
                self?.clickCount = count
                self?.statusMessage = "Running: \(count) clicks"
            }
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
        if let mouseLocation = NSEvent.mouseLocation.asCGPoint() {
            clickLocation = mouseLocation
        }
    }

    /// Update click location
    func updateClickLocation(x: Double, y: Double) {
        clickLocation = CGPoint(x: x, y: y)
    }
}

// MARK: - NSPoint Extension

private extension NSPoint {
    func asCGPoint() -> CGPoint {
        // Convert from AppKit coordinates (bottom-left origin) to CG coordinates (top-left origin)
        guard let screen = NSScreen.main else { return CGPoint(x: x, y: y) }
        let screenHeight = screen.frame.height
        return CGPoint(x: x, y: screenHeight - y)
    }
}
