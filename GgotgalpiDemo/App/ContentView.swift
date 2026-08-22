import SwiftUI

struct ContentView: View {
    private enum Tab: Hashable {
        case calendar, bookshelf
    }

    @State private var selectedTab: Tab = .calendar
    @State private var interactiveOffset: CGFloat = 0
    @State private var isInteractiveSwipe = false
    @Namespace private var tabSelectionNamespace

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
        // 외곽 글라스 쉘은 제거하고, 선택 캡슐의 시스템 전환 효과만 남깁니다.
        tabDockContents
    }

    private var tabDockContents: some View {
        Group {
            if #available(iOS 26.0, *) {
                GlassEffectContainer(spacing: 0) {
                    ZStack(alignment: .leading) {
                        tabSelectionGlass
                            .frame(width: 73, height: 38)
                            .offset(x: selectedTab == .calendar ? 3 : 76)
                            .allowsHitTesting(false)
                            .animation(.spring(response: 0.42, dampingFraction: 0.94), value: selectedTab)

                        tabDockButtons
                    }
                    .glassEffect(.clear.interactive(), in: Capsule())
                    .glassEffectID("dock-surface", in: tabSelectionNamespace)
                }
            } else {
                tabDockButtons
                    .background(.ultraThinMaterial, in: Capsule())
            }
        }
        .frame(width: 152, height: 44)
    }

    private var tabDockButtons: some View {
        HStack(spacing: 0) {
            tabDockButton(title: "달력", symbol: "calendar", tab: .calendar)
            tabDockButton(title: "책장", symbol: "books.vertical", tab: .bookshelf)
        }
        .padding(3)
    }

    private func tabDockButton(title: String, symbol: String, tab: Tab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            activateTab(tab)
        } label: {
            tabPickerLabel(title: title, symbol: symbol, isSelected: isSelected)
                .frame(width: 73, height: 38)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    @ViewBuilder
    private var tabSelectionGlass: some View {
        if #available(iOS 26.0, *) {
            Capsule()
                .fill(.clear)
                .glassEffect(.regular.interactive(), in: Capsule())
                .glassEffectID("dock-selection", in: tabSelectionNamespace)
        } else {
            Capsule()
                .fill(.ultraThinMaterial)
        }
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

    /// 선택 캡슐만 매끄럽게 이동시켜 전환 뒤의 튕김은 만들지 않습니다.
    private func activateTab(_ tab: Tab) {
        guard selectedTab != tab else { return }

        withAnimation(.spring(response: 0.42, dampingFraction: 0.94)) {
            selectedTab = tab
            interactiveOffset = 0
        }
    }
}
