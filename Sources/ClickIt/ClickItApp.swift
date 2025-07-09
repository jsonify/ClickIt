import SwiftUI

@main
struct ClickItApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 300, height: 400)
    }
}
