//
//  SimpleCursorManager.swift
//  ClickIt Lite
//
//  Manages custom cursor for ClickIt Lite application.
//

import AppKit
import SwiftUI

class SimpleCursorManager {

    // MARK: - Singleton

    static let shared = SimpleCursorManager()

    // MARK: - Properties

    private var customCursor: NSCursor?
    private var originalCursor: NSCursor?

    // MARK: - Initialization

    private init() {
        setupCustomCursor()
    }

    // MARK: - Public Methods

    /// Activates the custom target cursor system-wide
    func activateCustomCursor() {
        guard let customCursor = customCursor else {
            print("❌ Custom cursor not available")
            return
        }

        // Store original cursor for potential restoration
        originalCursor = NSCursor.current

        // Set custom cursor
        customCursor.set()

        print("✅ Custom target cursor activated")
    }

    /// Restores the default system cursor
    func restoreDefaultCursor() {
        NSCursor.arrow.set()
        print("✅ Default cursor restored")
    }

    // MARK: - Private Methods

    private func setupCustomCursor() {
        // Try to load the target image from resources
        guard let imageURL = Bundle.main.url(forResource: "target-64", withExtension: "png"),
              let image = NSImage(contentsOf: imageURL) else {
            print("❌ Failed to load target-64.png from resources")
            return
        }

        // Set the cursor size (64x64 pixels)
        image.size = NSSize(width: 64, height: 64)

        // Create cursor with hotspot at center (32, 32)
        let hotspot = NSPoint(x: 32, y: 32)
        customCursor = NSCursor(image: image, hotSpot: hotspot)

        print("✅ Custom cursor loaded successfully")
    }
}
