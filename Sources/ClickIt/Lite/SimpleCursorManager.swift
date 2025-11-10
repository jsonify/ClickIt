//
//  SimpleCursorManager.swift
//  ClickIt Lite
//
//  Manages custom cursor for ClickIt Lite application.
//

import AppKit
import SwiftUI
import os.log

class SimpleCursorManager {

    // MARK: - Singleton

    static let shared = SimpleCursorManager()

    // MARK: - Properties

    private let logger = Logger(subsystem: LoggingConstants.subsystem, category: "SimpleCursorManager")
    private var customCursor: NSCursor?
    private var originalCursor: NSCursor?
    private var cursorUpdateTimer: Timer?
    private var isCursorActive = false

    // MARK: - Initialization

    private init() {
        setupCustomCursor()
    }

    // MARK: - Public Methods

    /// Activates the custom target cursor system-wide
    func activateCustomCursor() {
        guard let customCursor = customCursor else {
            logger.error("❌ Custom cursor not available")
            showDebugAlert("Cursor Failed", "Custom cursor could not be loaded. Check console for details.")
            return
        }

        // Prevent double activation
        if isCursorActive {
            logger.info("ℹ️ Custom cursor already active")
            return
        }

        isCursorActive = true

        // Store original cursor for potential restoration
        originalCursor = NSCursor.current

        // Set custom cursor immediately
        customCursor.set()

        // Keep re-setting the cursor on a timer to ensure it stays active
        // This is needed because macOS resets cursor on window focus changes and other events
        cursorUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.isCursorActive else { return }
            self.customCursor?.set()
        }

        logger.info("✅ Custom target cursor activated with continuous refresh")
        // Optional: Uncomment to show success alert
        // showDebugAlert("Cursor Active", "Custom target cursor has been activated")
    }

    /// Shows a debug alert (for development/debugging)
    private func showDebugAlert(_ title: String, _ message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    /// Restores the default system cursor
    func restoreDefaultCursor() {
        isCursorActive = false

        // Stop the cursor update timer
        cursorUpdateTimer?.invalidate()
        cursorUpdateTimer = nil

        // Restore arrow cursor
        NSCursor.arrow.set()

        logger.info("✅ Default cursor restored")
    }

    // MARK: - Private Methods

    /// Finds the correct resource bundle for Swift Package Manager
    private func findResourceBundle() -> Bundle {
        // For Swift 5.3+, Swift Package Manager automatically synthesizes a `Bundle.module` static property
        // for any target that includes resources. This is the modern and recommended way to access them.
        return Bundle.module
    }

    private func setupCustomCursor() {
        // Define cursor properties at the top for easy modification
        let cursorDimension: CGFloat = 64
        let cursorImageName = "target-\(Int(cursorDimension))"

        // Debug: Log bundle path
        logger.debug("🔍 Bundle path: \(Bundle.main.bundlePath)")
        logger.debug("🔍 Resource path: \(Bundle.main.resourcePath ?? "nil")")

        // Find the correct resource bundle for Swift Package Manager
        let bundle = findResourceBundle()
        logger.debug("🔍 Using bundle: \(bundle.bundlePath)")

        // Try to load the target image from resources
        guard let imageURL = bundle.url(forResource: cursorImageName, withExtension: "png") else {
            logger.error("❌ Failed to find \(cursorImageName).png in bundle")
            logger.error("🔍 Searched in: \(bundle.bundleURL)")

            // Try to list all resources
            if let resourcePath = bundle.resourcePath {
                do {
                    let items = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                    logger.debug("📁 Available resources in bundle: \(items)")
                } catch {
                    logger.error("❌ Could not list resources: \(error)")
                }
            }
            return
        }

        logger.debug("✅ Found image at: \(imageURL.path)")

        guard let image = NSImage(contentsOf: imageURL) else {
            logger.error("❌ Failed to load NSImage from: \(imageURL.path)")
            return
        }

        logger.debug("✅ NSImage loaded, original size: \(String(describing: image.size))")

        // Set the cursor size
        image.size = NSSize(width: cursorDimension, height: cursorDimension)

        // Create cursor with hotspot at center
        let hotspot = NSPoint(x: cursorDimension / 2, y: cursorDimension / 2)
        customCursor = NSCursor(image: image, hotSpot: hotspot)

        logger.info("✅ Custom cursor created successfully")
    }
}
