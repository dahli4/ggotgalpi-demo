import SwiftUI

@main
struct GgotgalpiDemoApp: App {
    @StateObject private var store = DemoStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
