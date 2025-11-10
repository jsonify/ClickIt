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
            showDebugAlert("Cursor Failed", "Custom cursor could not be loaded. Check console for details.")
            return
        }

        // Store original cursor for potential restoration
        originalCursor = NSCursor.current

        // Set custom cursor
        customCursor.set()

        print("✅ Custom target cursor activated")
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
        NSCursor.arrow.set()
        print("✅ Default cursor restored")
    }

    // MARK: - Private Methods

    private func setupCustomCursor() {
        // Debug: Print bundle path
        print("🔍 Bundle path: \(Bundle.main.bundlePath)")
        print("🔍 Resource path: \(Bundle.main.resourcePath ?? "nil")")

        // Try to load the target image from resources
        guard let imageURL = Bundle.main.url(forResource: "target-64", withExtension: "png") else {
            print("❌ Failed to find target-64.png in bundle")
            print("🔍 Searched in: \(Bundle.main.bundleURL)")

            // Try to list all resources
            if let resourcePath = Bundle.main.resourcePath {
                do {
                    let items = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                    print("📁 Available resources: \(items)")
                } catch {
                    print("❌ Could not list resources: \(error)")
                }
            }
            return
        }

        print("✅ Found image at: \(imageURL.path)")

        guard let image = NSImage(contentsOf: imageURL) else {
            print("❌ Failed to load NSImage from: \(imageURL.path)")
            return
        }

        print("✅ NSImage loaded, original size: \(image.size)")

        // Set the cursor size (64x64 pixels)
        image.size = NSSize(width: 64, height: 64)

        // Create cursor with hotspot at center (32, 32)
        let hotspot = NSPoint(x: 32, y: 32)
        customCursor = NSCursor(image: image, hotSpot: hotspot)

        print("✅ Custom cursor created successfully")
    }
}
