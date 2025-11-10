//
//  ClickItLiteApp.swift
//  ClickIt Lite
//
//  App entry point for ClickIt Lite - the simplified auto-clicker.
//
import SwiftUI

@main
struct ClickItLiteApp: App {

    init() {
        // Activate custom target cursor when app launches
        SimpleCursorManager.shared.activateCustomCursor()
    }

    var body: some Scene {
        WindowGroup {
            SimplifiedMainView()
        }
        .windowResizability(.contentSize)
    }
}
