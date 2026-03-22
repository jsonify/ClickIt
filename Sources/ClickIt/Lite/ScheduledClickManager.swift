//
//  ScheduledClickManager.swift
//  ClickIt Lite
//
//  Manages scheduling a single one-time click at a future date and time.
//  Uses LiteScheduler (DispatchSourceTimer) for ≤5ms firing accuracy.
//

import Foundation
import CoreGraphics
import AppKit
import os.log

/// Manages a single scheduled click that fires at a user-specified date and time.
@MainActor
final class ScheduledClickManager: ObservableObject {

    // MARK: - Types

    /// The current state of the scheduler.
    enum State: Equatable {
        case idle
        case scheduled(Date)
        case fired
    }

    /// Errors that can occur when scheduling a click.
    enum ScheduleError: Error, Equatable {
        case dateInPast
    }

    // MARK: - Published Properties

    @Published private(set) var state: State = .idle
    @Published private(set) var countdown: TimeInterval = 0

    // MARK: - Private Properties

    private let logger = Logger(subsystem: LoggingConstants.subsystem, category: "ScheduledClickManager")
    private let scheduler: LiteScheduler
    private let clickAction: () -> Void

    // MARK: - Callbacks

    /// Called immediately after the scheduled click fires, before state resets to idle.
    var executionHandler: (() -> Void)?

    // MARK: - Initialization

    /// Creates a scheduler with an injectable click action for testability.
    /// - Parameter clickAction: The action to perform when the scheduled time arrives.
    ///   Defaults to a left click at the current cursor position.
    init(clickAction: @escaping () -> Void = ScheduledClickManager.performLeftClickAtCursor) {
        self.clickAction = clickAction
        self.scheduler = LiteScheduler()
    }

    // MARK: - Public Methods

    /// Schedule a single click at the given future date.
    /// - Throws: `ScheduleError.dateInPast` if `date` is not in the future.
    func schedule(at date: Date) throws {
        guard date > Date() else {
            throw ScheduleError.dateInPast
        }
        state = .scheduled(date)
        countdown = date.timeIntervalSinceNow

        scheduler.countdownUpdateHandler = { [weak self] remaining in
            self?.countdown = remaining
        }

        scheduler.executionHandler = { [weak self] in
            self?.fire()
        }

        let scheduled = scheduler.schedule(for: date, task: { [weak self] in
            self?.clickAction()
        })

        if !scheduled {
            // Date slipped past between guard and schedule call — treat as past
            state = .idle
            countdown = 0
            throw ScheduleError.dateInPast
        }

        logger.info("Scheduled click at \(date)")
    }

    /// Cancel the pending scheduled click and reset to idle.
    func cancel() {
        scheduler.cancel()
        state = .idle
        countdown = 0
        logger.info("Scheduled click cancelled")
    }

    // MARK: - Private Methods

    private func fire() {
        state = .fired
        countdown = 0
        logger.info("Scheduled click fired")
        executionHandler?()
        state = .idle
    }

    // MARK: - Default Click Action

    /// Performs a single left click at the current cursor position.
    /// Marked `nonisolated` so it can be used as a default parameter value.
    /// Always called from the `@MainActor`-isolated `fire()` method, so
    /// `MainActor.assumeIsolated` is safe here.
    nonisolated private static func performLeftClickAtCursor() {
        let point = MainActor.assumeIsolated { cgPoint(from: NSEvent.mouseLocation) }

        guard let mouseDown = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseDown,
            mouseCursorPosition: point,
            mouseButton: .left
        ) else { return }
        mouseDown.post(tap: .cghidEventTap)

        guard let mouseUp = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseUp,
            mouseCursorPosition: point,
            mouseButton: .left
        ) else { return }
        mouseUp.post(tap: .cghidEventTap)
    }

    /// Converts an AppKit NSPoint (bottom-left origin) to a CoreGraphics CGPoint (top-left origin).
    nonisolated private static func cgPoint(from nsPoint: NSPoint) -> CGPoint {
        if let globalMaxY = NSScreen.screens.map({ $0.frame.maxY }).max() {
            return CGPoint(x: nsPoint.x, y: globalMaxY - nsPoint.y)
        }
        if let mainScreen = NSScreen.main {
            return CGPoint(x: nsPoint.x, y: mainScreen.frame.height - nsPoint.y)
        }
        return CGPoint(x: nsPoint.x, y: nsPoint.y)
    }
}
