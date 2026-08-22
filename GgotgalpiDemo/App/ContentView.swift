import SwiftUI

struct ContentView: View {
    private enum Tab: Hashable {
        case calendar, bookshelf
    }

    @State private var selectedTab: Tab = .calendar

    var body: some View {
        TabView(selection: $selectedTab) {
            CalendarView()
                .tabItem { Label("달력", systemImage: "calendar") }
                .tag(Tab.calendar)

            BookshelfView()
                .tabItem { Label("책장", systemImage: "books.vertical") }
                .tag(Tab.bookshelf)
        }
        .tint(GgotgalpiTheme.accent)
        .ignoresSafeArea(.keyboard)
    }
}
