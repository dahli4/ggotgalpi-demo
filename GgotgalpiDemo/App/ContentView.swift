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
        .highPriorityGesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    switchTabForHorizontalSwipe(value)
                }
        )
    }

    /// 하단 탭 외에도 화면을 가로로 쓸어 넘겨 달력과 책장 사이를 빠르게 오갈 수 있게 합니다.
    private func switchTabForHorizontalSwipe(_ value: DragGesture.Value) {
        let horizontalDistance = value.translation.width
        let verticalDistance = value.translation.height
        let isHorizontalSwipe = abs(horizontalDistance) > abs(verticalDistance)
        let minimumSwipeDistance: CGFloat = 70

        guard isHorizontalSwipe, abs(horizontalDistance) >= minimumSwipeDistance else { return }

        withAnimation(.easeInOut(duration: 0.22)) {
            if selectedTab == .calendar, horizontalDistance < 0 {
                selectedTab = .bookshelf
            } else if selectedTab == .bookshelf, horizontalDistance > 0 {
                selectedTab = .calendar
            }
        }
    }
}
