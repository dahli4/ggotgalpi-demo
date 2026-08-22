import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var store: DemoStore
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var displayedMonth = Calendar.current.startOfMonth(for: Date())
    @State private var selectedReadingStatus: ReadingStatus = .all
    @State private var selectedCategory: BookCategory = .all
    @State private var isShowingFilters = false
    @State private var reorderRequest: CalendarBookReorderRequest?
    @State private var isShowingDayEntries = false
    @State private var isShowingSearch = false

    private func matchesCalendarFilters(_ entry: ReadingEntry) -> Bool {
        guard let book = store.book(for: entry.bookID), !book.isHiddenFromCalendar else {
            return false
        }
        let matchesStatus = selectedReadingStatus == .all || book.readingStatus == selectedReadingStatus
        let matchesCategory = selectedCategory == .all || book.category == selectedCategory
        return matchesStatus && matchesCategory
    }

    private func entries(on date: Date) -> [ReadingEntry] {
        store.entries(on: date).filter(matchesCalendarFilters)
    }

    private func books(on date: Date) -> [Book] {
        let latestEntries = Dictionary(grouping: entries(on: date), by: \.bookID).compactMapValues { entries in
            entries.max { $0.createdAt < $1.createdAt }
        }
        let defaultOrder = latestEntries.values
            .sorted { $0.createdAt > $1.createdAt }
            .map(\.bookID)
        let orderedIDs = store.orderedBookIDs(for: date, defaultOrder: defaultOrder)
        return orderedIDs.compactMap(store.book(for:))
    }

    private var hasActiveFilter: Bool {
        selectedReadingStatus != .all || selectedCategory != .all
    }

    private var filterSummary: String {
        [
            selectedReadingStatus == .all ? nil : selectedReadingStatus.rawValue,
            selectedCategory == .all ? nil : selectedCategory.rawValue
        ]
        .compactMap { $0 }
        .joined(separator: " · ")
    }

    private var monthlyEntries: [ReadingEntry] {
        store.entries.filter {
            Calendar.current.isDate($0.date, equalTo: displayedMonth, toGranularity: .month)
                && matchesCalendarFilters($0)
        }
    }

    private var mostRecentMonthlyEntry: ReadingEntry? {
        monthlyEntries.max { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: GgotgalpiTheme.Spacing.section) {
                    MonthlyCalendarGrid(
                        displayedMonth: $displayedMonth,
                        selectedDate: $selectedDate,
                        books: { books(on: $0) },
                        selectDate: { date in
                            selectedDate = date
                            isShowingDayEntries = true
                        },
                        requestReorder: { date in
                            let books = books(on: date)
                            guard books.count > 1 else { return }
                            reorderRequest = CalendarBookReorderRequest(date: date, books: books)
                        }
                    )

                    CalendarMonthlySummary(
                        entries: monthlyEntries,
                        latestEntry: mostRecentMonthlyEntry,
                        latestBook: mostRecentMonthlyEntry.flatMap { store.book(for: $0.bookID) }
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, GgotgalpiTheme.Spacing.screen)
                .padding(.top, GgotgalpiTheme.Spacing.control)
                .padding(.bottom, GgotgalpiTheme.Spacing.compact)
            }
            .scrollIndicators(.hidden)
            // 달력 카드 밖은 거의 흰색의 웜 화이트로 두고, 따뜻한 베이지 톤은 월간 달력 카드에만 남깁니다.
            .background(GgotgalpiTheme.calendarCanvas)
            .toolbarBackground(GgotgalpiTheme.calendarCanvas, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 0) {
                        if hasActiveFilter {
                            Button {
                                isShowingFilters = true
                            } label: {
                                Text(filterSummary)
                                    .font(.caption.weight(.medium))
                                    .lineLimit(1)
                                    .padding(.horizontal, 10)
                                    .frame(minHeight: 36)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("적용된 필터: \(filterSummary)")

                            Divider()
                                .frame(height: 18)
                                .padding(.horizontal, 2)
                        }

                        Button {
                            isShowingFilters = true
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .frame(width: 36, height: 36)
                        }
                        .accessibilityLabel("달력 필터")

                        Button {
                            isShowingSearch = true
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .frame(width: 36, height: 36)
                        }
                        .accessibilityLabel("통합 검색")
                    }
                    .foregroundStyle(GgotgalpiTheme.ink)
                }
            }
        }
        .background(GgotgalpiTheme.calendarCanvas.ignoresSafeArea())
        .tint(GgotgalpiTheme.accent)
        .sheet(item: $reorderRequest) { request in
            CalendarBookOrderEditor(date: request.date, books: request.books) { bookIDs in
                store.saveCalendarBookOrder(bookIDs, for: request.date)
            }
        }
        .sheet(isPresented: $isShowingFilters) {
            CalendarFilterSheet(
                selectedReadingStatus: $selectedReadingStatus,
                selectedCategory: $selectedCategory
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $isShowingDayEntries) {
            CalendarDayEntriesSheet(
                date: selectedDate,
                entries: entries(on: selectedDate),
                orderedBooks: books(on: selectedDate),
                saveOrder: { bookIDs in
                    store.saveCalendarBookOrder(bookIDs, for: selectedDate)
                }
            )
        }
        .sheet(isPresented: $isShowingSearch) {
            UnifiedSearchView()
        }
    }
}

private struct CalendarMonthlySummary: View {
    let entries: [ReadingEntry]
    let latestEntry: ReadingEntry?
    let latestBook: Book?

    private var readBookCount: Int {
        Set(entries.map(\.bookID)).count
    }

    private var readPageCount: Int {
        entries.reduce(0) { $0 + max(0, $1.pageTo - $1.pageFrom + 1) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: GgotgalpiTheme.Spacing.control) {
            Text("이번 달 요약")
                .font(.system(.headline, design: .serif))
                .foregroundStyle(GgotgalpiTheme.ink)

            HStack(spacing: 0) {
                CalendarSummaryMetric(value: "\(readBookCount)권", title: "읽은 책")
                CalendarSummaryMetric(value: "\(entries.count)개", title: "감상 기록")
                CalendarSummaryMetric(value: "\(readPageCount)쪽", title: "읽은 페이지")
            }

            if let latestEntry, let latestBook {
                Divider()

                VStack(alignment: .leading, spacing: 5) {
                    Text("최근 감상 · \(latestEntry.date.shortKoreanDate)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(GgotgalpiTheme.secondaryInk)

                    Text(latestBook.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(GgotgalpiTheme.ink)

                    Text(latestEntry.note)
                        .font(.caption)
                        .foregroundStyle(GgotgalpiTheme.secondaryInk)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            } else {
                Text("이번 달에 남긴 감상이 아직 없어요.")
                    .font(.subheadline)
                    .foregroundStyle(GgotgalpiTheme.secondaryInk)
            }
        }
    }
}

private struct CalendarSummaryMetric: View {
    let value: String
    let title: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(.title3, design: .serif).weight(.semibold))
                .foregroundStyle(GgotgalpiTheme.ink)
            Text(title)
                .font(.caption2)
                .foregroundStyle(GgotgalpiTheme.secondaryInk)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct CalendarFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedReadingStatus: ReadingStatus
    @Binding var selectedCategory: BookCategory

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: GgotgalpiTheme.Spacing.section) {
                Text("달력에 표시할 감상을 골라 보세요.")
                    .font(.subheadline)
                    .foregroundStyle(GgotgalpiTheme.secondaryInk)

                VStack(alignment: .leading, spacing: GgotgalpiTheme.Spacing.compact) {
                    Text("읽은 상태")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(GgotgalpiTheme.secondaryInk)

                    ReadingStatusUnderlineTabs(selection: $selectedReadingStatus)
                }

                VStack(alignment: .leading, spacing: GgotgalpiTheme.Spacing.compact) {
                    Text("장르")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(GgotgalpiTheme.secondaryInk)

                    CalendarCategoryTabs(selection: $selectedCategory)
                }

                Spacer()
            }
            .padding(.horizontal, GgotgalpiTheme.Spacing.screen)
            .padding(.top, GgotgalpiTheme.Spacing.content)
            .navigationTitle("필터")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("초기화") {
                        selectedReadingStatus = .all
                        selectedCategory = .all
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("완료") { dismiss() }
                }
            }
        }
        .paperBackground()
    }
}

private struct CalendarBookReorderRequest: Identifiable {
    let date: Date
    let books: [Book]

    var id: Date { date }
}

private struct CalendarDayEntriesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: DemoStore
    @State private var books: [Book]
    @State private var editMode: EditMode = .inactive

    let date: Date
    let entries: [ReadingEntry]
    let saveOrder: ([UUID]) -> Void

    init(
        date: Date,
        entries: [ReadingEntry],
        orderedBooks: [Book],
        saveOrder: @escaping ([UUID]) -> Void
    ) {
        self.date = date
        self.entries = entries
        self.saveOrder = saveOrder
        _books = State(initialValue: orderedBooks)
    }

    private var canReorder: Bool {
        books.count > 1
    }

    private func entries(for book: Book) -> [ReadingEntry] {
        entries
            .filter { $0.bookID == book.id }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            List {
                if entries.isEmpty {
                    ReadingEmptyState(
                        title: "아직 남긴 감상이 없어요",
                        message: "책장에서 작품을 고르고 이 날의 마음을 기록해 보세요."
                    )
                    .listRowBackground(GgotgalpiTheme.paper)
                } else {
                    if canReorder {
                        Section {
                            Text(editMode == .active
                                 ? "오른쪽 손잡이를 드래그해 순서를 정하세요. 맨 위 작품이 달력의 최전면 표지가 됩니다."
                                 : "감상문을 길게 눌러 작품 순서를 바꿀 수 있어요.")
                                .font(.caption)
                                .foregroundStyle(GgotgalpiTheme.secondaryInk)
                                .listRowBackground(GgotgalpiTheme.paperDeep.opacity(0.58))
                        }
                    }

                    Section {
                        ForEach(books) { book in
                            CalendarDayBookEntryRow(book: book, entries: entries(for: book))
                                .contentShape(Rectangle())
                                .onLongPressGesture(minimumDuration: 0.45) {
                                    guard canReorder else { return }
                                    editMode = .active
                                }
                        }
                        .onMove { source, destination in
                            books.move(fromOffsets: source, toOffset: destination)
                            saveOrder(books.map(\.id))
                        }
                    }
                }
            }
            .environment(\.editMode, $editMode)
            .scrollContentBackground(.hidden)
            .background(GgotgalpiTheme.paper)
            .navigationTitle(date.formatted(.dateTime.month().day().weekday(.wide).locale(Locale(identifier: "ko_KR"))))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if editMode == .active {
                        Button("정렬 완료") { editMode = .inactive }
                    } else {
                        Button("닫기") { dismiss() }
                    }
                }
            }
        }
        .paperBackground()
    }
}

private struct CalendarDayBookEntryRow: View {
    let book: Book
    let entries: [ReadingEntry]

    var body: some View {
        HStack(alignment: .top, spacing: GgotgalpiTheme.Spacing.control) {
            BookColorMark(title: book.title, color: book.coverColor, size: 44)

            VStack(alignment: .leading, spacing: GgotgalpiTheme.Spacing.compact) {
                Text(book.title)
                    .font(.headline)
                    .foregroundStyle(GgotgalpiTheme.ink)

                ForEach(entries) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("p.\(entry.pageFrom)-\(entry.pageTo)")
                                .font(.caption)
                                .foregroundStyle(GgotgalpiTheme.secondaryInk)
                            Spacer()
                            Text("\(entry.readingRound)회독")
                                .font(.caption)
                                .foregroundStyle(GgotgalpiTheme.secondaryInk)
                        }

                        Text(entry.note)
                            .font(.body)
                            .foregroundStyle(GgotgalpiTheme.ink)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if entry.id != entries.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

private struct MonthlyCalendarGrid: View {
    @Binding var displayedMonth: Date
    @Binding var selectedDate: Date
    let books: (Date) -> [Book]
    let selectDate: (Date) -> Void
    let requestReorder: (Date) -> Void

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let weekdaySymbols = ["일", "월", "화", "수", "목", "금", "토"]

    private var days: [Date?] {
        let firstDay = calendar.startOfMonth(for: displayedMonth)
        let leadingDays = calendar.component(.weekday, from: firstDay) - 1
        let numberOfDays = calendar.range(of: .day, in: .month, for: firstDay)?.count ?? 0
        let monthDays = (0..<numberOfDays).compactMap { calendar.date(byAdding: .day, value: $0, to: firstDay) }
        let cells = Array(repeating: nil as Date?, count: leadingDays) + monthDays
        let trailingDays = (7 - cells.count % 7) % 7
        return cells + Array(repeating: nil as Date?, count: trailingDays)
    }

    private var weekCount: Int {
        max(days.count / 7, 1)
    }

    private var calendarHeight: CGFloat {
        let weekdayHeight: CGFloat = 18
        let headerHeight: CGFloat = 44
        let cardInsets: CGFloat = 16
        return cardInsets + headerHeight + GgotgalpiTheme.Spacing.control + weekdayHeight + CGFloat(weekCount) * 66
    }

    var body: some View {
        GeometryReader { proxy in
            // 화면이 큰 경우에도 달력만 과도하게 길어지지 않도록 행 높이에 상한을 둡니다.
            let weekdayHeight: CGFloat = 18
            let headerHeight: CGFloat = 44
            let calendarCardInsets: CGFloat = 16
            let contentHeight = max(0, proxy.size.height - calendarCardInsets - headerHeight - GgotgalpiTheme.Spacing.control - weekdayHeight)
            let dayCellHeight = min(66, max(58, contentHeight / CGFloat(weekCount)))

            VStack(spacing: GgotgalpiTheme.Spacing.control) {
                HStack {
                    Button {
                        displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .accessibilityLabel("이전 달")

                    Spacer()

                    Text(monthTitle)
                        .font(.headline)
                        .foregroundStyle(GgotgalpiTheme.ink)

                    Spacer()

                    Button {
                        displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .accessibilityLabel("다음 달")
                }
                .foregroundStyle(GgotgalpiTheme.ink)
                .frame(height: headerHeight)

                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(weekdaySymbols.indices, id: \.self) { index in
                        Text(weekdaySymbols[index])
                            .font(.caption.weight(.medium))
                            .foregroundStyle(GgotgalpiTheme.secondaryInk)
                            .frame(maxWidth: .infinity, minHeight: weekdayHeight)
                    }

                    ForEach(7..<(7 + days.count), id: \.self) { gridIndex in
                        let index = gridIndex - 7
                        let date = days[index]
                        CalendarDayCell(
                            date: date,
                            books: date.map(books) ?? [],
                            isSelected: date.map { calendar.isDate($0, inSameDayAs: selectedDate) } ?? false,
                            showsLeadingLine: index % 7 != 0,
                            showsTopLine: index >= 7,
                            select: selectDate,
                            requestReorder: requestReorder
                        )
                        .frame(height: dayCellHeight)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(GgotgalpiTheme.paper.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(GgotgalpiTheme.paperDeep.opacity(0.75), lineWidth: 0.8)
            }
            .shadow(color: .black.opacity(0.045), radius: 8, y: 3)
        }
        .frame(height: calendarHeight)
    }

    private var monthTitle: String {
        let components = calendar.dateComponents([.year, .month], from: displayedMonth)
        let year = (components.year ?? 0) % 100
        let month = components.month ?? 0
        return "\(year)년 \(month)월"
    }
}

private struct CalendarDayCell: View {
    let date: Date?
    let books: [Book]
    let isSelected: Bool
    let showsLeadingLine: Bool
    let showsTopLine: Bool
    let select: (Date) -> Void
    let requestReorder: (Date) -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let date {
                if books.isEmpty {
                    Button {
                        select(date)
                    } label: {
                        Text(date.formatted(.dateTime.day()))
                            .font(.subheadline.weight(isSelected ? .bold : .regular))
                            .foregroundStyle(GgotgalpiTheme.ink)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(date.shortKoreanDate)
                    .padding(8)
                } else {
                    CalendarBookCoverStack(books: books, date: date, isSelected: isSelected)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            select(date)
                        }
                        .onLongPressGesture(minimumDuration: 0.55) {
                            if books.count > 1 {
                                requestReorder(date)
                            }
                        }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .overlay(alignment: .leading) {
            if showsLeadingLine {
                Rectangle()
                    .fill(GgotgalpiTheme.calendarGridLine)
                    .frame(width: 0.5)
            }
        }
        .overlay(alignment: .top) {
            if showsTopLine {
                Rectangle()
                    .fill(GgotgalpiTheme.calendarGridLine)
                    .frame(height: 0.5)
            }
        }
    }
}

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        self.date(from: dateComponents([.year, .month], from: date)) ?? date
    }
}
