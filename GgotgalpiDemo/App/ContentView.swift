import SwiftUI

struct ContentView: View {
    private enum Tab: Hashable {
        case calendar, bookshelf
    }

    @State private var selectedTab: Tab = .calendar
    @State private var interactiveOffset: CGFloat = 0
    @State private var isInteractiveSwipe = false

    private let edgeActivationWidth: CGFloat = 28
    private let completionRatio: CGFloat = 0.30

    var body: some View {
        ZStack {
            screenBackground
                .ignoresSafeArea()

            GeometryReader { proxy in
                let pageWidth = proxy.size.width

                ZStack {
                    CalendarView()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .offset(x: calendarOffset(pageWidth: pageWidth))

                    BookshelfView()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .offset(x: bookshelfOffset(pageWidth: pageWidth))
                }
                .clipped()
                .overlay(alignment: selectedTab == .calendar ? .trailing : .leading) {
                    Color.clear
                        .frame(width: edgeActivationWidth)
                        .frame(maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 8)
                                .onChanged { value in
                                    updateInteractiveSwipe(value, pageWidth: pageWidth)
                                }
                                .onEnded { value in
                                    finishInteractiveSwipe(value, pageWidth: pageWidth)
                                }
                        )
                }
            }
        }
        .ignoresSafeArea()
        .overlay(alignment: .bottom) {
            tabDock
        }
        .tint(GgotgalpiTheme.accent)
        .ignoresSafeArea(.keyboard)
    }

    private var screenBackground: Color {
        GgotgalpiTheme.paper
    }

    /// 화면 가장자리의 전용 영역에서 시작한 명확한 가로 드래그에만 반응해, 세로 스크롤과 충돌하지 않게 합니다.
    private func updateInteractiveSwipe(_ value: DragGesture.Value, pageWidth: CGFloat) {
        let horizontalDistance = value.translation.width
        let verticalDistance = value.translation.height

        guard abs(horizontalDistance) > abs(verticalDistance) else { return }

        if !isInteractiveSwipe {
            let isAllowedDirection = switch selectedTab {
            case .calendar: horizontalDistance < 0
            case .bookshelf: horizontalDistance > 0
            }

            guard isAllowedDirection else {
                return
            }
            isInteractiveSwipe = true
        }

        interactiveOffset = clampedInteractiveOffset(horizontalDistance, pageWidth: pageWidth)
    }

    private func finishInteractiveSwipe(_ value: DragGesture.Value, pageWidth: CGFloat) {
        defer { isInteractiveSwipe = false }

        guard isInteractiveSwipe else { return }

        if abs(interactiveOffset) >= pageWidth * completionRatio {
            activateTab(interactiveOffset < 0 ? .bookshelf : .calendar)
        } else {
            withAnimation(.easeOut(duration: 0.24)) {
                interactiveOffset = 0
            }
        }
    }

    private func clampedInteractiveOffset(_ value: CGFloat, pageWidth: CGFloat) -> CGFloat {
        switch selectedTab {
        case .calendar:
            return min(0, max(-pageWidth, value))
        case .bookshelf:
            return max(0, min(pageWidth, value))
        }
    }

    private func calendarOffset(pageWidth: CGFloat) -> CGFloat {
        selectedTab == .calendar ? interactiveOffset : -pageWidth + interactiveOffset
    }

    private func bookshelfOffset(pageWidth: CGFloat) -> CGFloat {
        selectedTab == .bookshelf ? interactiveOffset : pageWidth + interactiveOffset
    }

    private var tabDock: some View {
        tabDockSurface
            // 전체 화면 위에 떠 있으면서 홈 인디케이터 바로 위에 붙도록 안전 영역 안에서만 내립니다.
            .padding(.bottom, -8)
    }

    private var tabDockSurface: some View {
        tabDockContents
    }

    private var tabDockContents: some View {
        ZStack {
            Picker("화면 전환", selection: tabSelection) {
                Text(" ").tag(Tab.calendar)
                Text(" ").tag(Tab.bookshelf)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            HStack(spacing: 0) {
                tabPickerLabel(title: "달력", symbol: "calendar", isSelected: selectedTab == .calendar)
                tabPickerLabel(title: "책장", symbol: "books.vertical", isSelected: selectedTab == .bookshelf)
            }
            .allowsHitTesting(false)
        }
        .frame(width: 152, height: 44)
    }

    private var tabSelection: Binding<Tab> {
        Binding(
            get: { selectedTab },
            set: { activateTab($0) }
        )
    }

    private func tabPickerLabel(title: String, symbol: String, isSelected: Bool) -> some View {
        VStack(spacing: 2) {
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
            Text(title)
                .font(.caption2.weight(.medium))
        }
        .foregroundStyle(isSelected ? GgotgalpiTheme.ink : GgotgalpiTheme.secondaryInk)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// 책장 상단의 세그먼트와 같은 시스템 선택 전환을 사용합니다.
    private func activateTab(_ tab: Tab) {
        guard selectedTab != tab else { return }

        selectedTab = tab
        interactiveOffset = 0
    }
}
