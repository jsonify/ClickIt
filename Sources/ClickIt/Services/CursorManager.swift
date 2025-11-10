//
//  CursorManager.swift
//  ClickIt
//
//  Manages custom cursor states for active target mode
//

import Cocoa
import os.log

/// Manages cursor appearance for different automation modes
final class CursorManager {
    static let shared = CursorManager()

    private let logger = Logger(subsystem: "com.clickit.app", category: "CursorManager")
    private var isTargetCursorActive = false
    private var cursorUpdateTimer: Timer?

    private init() {}

    /// Shows the target/crosshair cursor for active target mode
    func showTargetCursor() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if !self.isTargetCursorActive {
                self.isTargetCursorActive = true

                // Set the cursor immediately
                NSCursor.crosshair.set()

                // Keep re-setting the cursor on a timer to ensure it stays active
                // This is needed because system can reset cursor on window focus changes
                self.cursorUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                    guard let self = self, self.isTargetCursorActive else { return }
                    NSCursor.crosshair.set()
                }

                self.logger.info("Target cursor activated with timer refresh")
            }
        }
    }

    /// Restores the normal system cursor
    func restoreNormalCursor() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if self.isTargetCursorActive {
                self.isTargetCursorActive = false

                // Stop the cursor update timer
                self.cursorUpdateTimer?.invalidate()
                self.cursorUpdateTimer = nil

                // Restore arrow cursor
                NSCursor.arrow.set()

                self.logger.info("Normal cursor restored")
            }
        }
    }

    /// Force restore cursor (useful for cleanup on app termination)
    func forceRestoreNormalCursor() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.isTargetCursorActive = false
            self.cursorUpdateTimer?.invalidate()
            self.cursorUpdateTimer = nil
            NSCursor.arrow.set()

            self.logger.info("Cursor forcefully restored")
        }
    }
}
