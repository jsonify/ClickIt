//
//  ClickItLiteApp.swift
//  ClickIt Lite
//
//  App entry point for ClickIt Lite - the simplified auto-clicker.
//

import SwiftUI

@main
struct ClickItLiteApp: App {

    var body: some Scene {
        WindowGroup {
            SimplifiedMainView()
        }
        .windowResizability(.contentSize)
    }
}
