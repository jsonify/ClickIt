//
//  ClickItLiteApp.swift
//  ClickIt Lite
//
//  App entry point for ClickIt Lite - the simplified auto-clicker.
//
//  NOTE: @main is commented out by default. To use ClickIt Lite instead of the full version:
//  1. Comment out @main in Sources/ClickIt/ClickItApp.swift
//  2. Uncomment @main below
//  3. Build normally
//

import SwiftUI

// @main  // Uncomment to use ClickIt Lite as the main app
struct ClickItLiteApp: App {

    var body: some Scene {
        WindowGroup {
            SimplifiedMainView()
        }
        .windowResizability(.contentSize)
    }
}
