import SwiftUI
import SwiftData

@main
struct GgotgalpiDemoApp: App {
    private let modelContainer: ModelContainer
    @StateObject private var store: DemoStore

    init() {
        do {
            let container = try ModelContainer(for: Book.self, ReadingEntry.self)
            modelContainer = container
            _store = StateObject(wrappedValue: DemoStore(modelContext: container.mainContext))
        } catch {
            fatalError("SwiftData 컨테이너를 만들지 못했습니다: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .modelContainer(modelContainer)
    }
}
