//
//  SimpleClickEngine.swift
//  ClickIt Lite
//
//  Simplified click engine with core functionality only.
//

import Foundation
import CoreGraphics

/// Simple click engine for basic auto-clicking
@MainActor
final class SimpleClickEngine {

    // MARK: - Types

    enum ClickType {
        case left
        case right
    }

    // MARK: - Properties

    private var isRunning = false
    private var clickTask: Task<Void, Never>?
    private var clickCount = 0

    // MARK: - Public Methods

    /// Start clicking at specified location
    func startClicking(
        at point: CGPoint,
        interval: TimeInterval,
        clickType: ClickType,
        onUpdate: @escaping (Int) -> Void
    ) {
        startClicking(
            pointProvider: { point },
            interval: interval,
            clickType: clickType,
            onUpdate: onUpdate
        )
    }

    /// Start clicking with dynamic point generation
    func startClicking(
        pointProvider: @escaping () -> CGPoint,
        interval: TimeInterval,
        clickType: ClickType,
        onUpdate: @escaping (Int) -> Void
    ) {
        guard !isRunning else { return }

        isRunning = true
        clickCount = 0

        clickTask = Task { [weak self] in
            guard let self = self else { return }

            while !Task.isCancelled && self.isRunning {
                // Get current point (can be static or dynamic)
                let point = pointProvider()

                // Perform click
                await self.performClick(at: point, type: clickType)
                self.clickCount += 1

                // Update UI (already on MainActor, no need to wrap)
                onUpdate(self.clickCount)

                // Wait for interval
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }
    }

    /// Stop clicking
    func stopClicking() {
        isRunning = false
        clickTask?.cancel()
        clickTask = nil
    }

    /// Get current click count
    func getClickCount() -> Int {
        return clickCount
    }

    // MARK: - Private Methods

    private func performClick(at point: CGPoint, type: ClickType) async {
        let mouseDownType: CGEventType
        let mouseUpType: CGEventType
        let mouseButton: CGMouseButton

        switch type {
        case .left:
            mouseDownType = .leftMouseDown
            mouseUpType = .leftMouseUp
            mouseButton = .left
        case .right:
            mouseDownType = .rightMouseDown
            mouseUpType = .rightMouseUp
            mouseButton = .right
        }

        // Debug logging
        print("🖱️ Performing \(type) click at (\(Int(point.x)), \(Int(point.y)))")

        // Create and post mouse down event
        if let mouseDown = CGEvent(
            mouseEventSource: nil,
            mouseType: mouseDownType,
            mouseCursorPosition: point,
            mouseButton: mouseButton
        ) {
            mouseDown.post(tap: .cghidEventTap)
        }

        // Small delay between down and up (async to avoid blocking UI)
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms

        // Create and post mouse up event
        if let mouseUp = CGEvent(
            mouseEventSource: nil,
            mouseType: mouseUpType,
            mouseCursorPosition: point,
            mouseButton: mouseButton
        ) {
            mouseUp.post(tap: .cghidEventTap)
        }
    }
}
