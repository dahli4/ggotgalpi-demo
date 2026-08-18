import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var store: DemoStore
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var displayedMonth = Calendar.current.startOfMonth(for: Date())
    @State private var selectedCategory: BookCategory = .all
    @State private var reorderRequest: CalendarBookReorderRequest?
    @State private var isShowingDayEntries = false

    private func entries(on date: Date) -> [ReadingEntry] {
        store.entries(on: date).filter { entry in
            guard let book = store.book(for: entry.bookID), !book.isHiddenFromCalendar else {
                return false
            }
            return selectedCategory == .all || book.category == selectedCategory
        }
    }

    private func allCalendarEntries(on date: Date) -> [ReadingEntry] {
        store.entries(on: date).filter { entry in
            store.book(for: entry.bookID)?.isHiddenFromCalendar == false
        }
    }

    private func books(on date: Date, applyingCategoryFilter: Bool) -> [Book] {
        let sourceEntries = applyingCategoryFilter ? entries(on: date) : allCalendarEntries(on: date)
        let latestEntries = Dictionary(grouping: sourceEntries, by: \.bookID).compactMapValues { entries in
            entries.max { $0.createdAt < $1.createdAt }
        }
        let defaultOrder = latestEntries.values
            .sorted { $0.createdAt > $1.createdAt }
            .map(\.bookID)
        let orderedIDs = store.orderedBookIDs(for: date, defaultOrder: defaultOrder)
        return orderedIDs.compactMap(store.book(for:))
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: GgotgalpiTheme.Spacing.section) {
                CategoryPicker(selection: $selectedCategory)
                    .frame(minHeight: 32)
                    .layoutPriority(1)

                MonthlyCalendarGrid(
                    displayedMonth: $displayedMonth,
                    selectedDate: $selectedDate,
                    books: { books(on: $0, applyingCategoryFilter: true) },
                    selectDate: { date in
                        selectedDate = date
                        isShowingDayEntries = true
                    },
                    requestReorder: { date in
                        let books = books(on: date, applyingCategoryFilter: false)
                        guard books.count > 1 else { return }
                        reorderRequest = CalendarBookReorderRequest(date: date, books: books)
                    }
                )
                .frame(maxHeight: .infinity)
                .layoutPriority(-1)
            }
            .padding(.horizontal, GgotgalpiTheme.Spacing.screen)
            .padding(.bottom, GgotgalpiTheme.Spacing.compact)
            .background(GgotgalpiTheme.paper)
            .navigationTitle("캘린더")
            .toolbarBackground(GgotgalpiTheme.paper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("오늘") {
                        selectedDate = Calendar.current.startOfDay(for: Date())
                    }
                    .accessibilityHint("오늘 날짜로 이동합니다")
                }
            }
        }
        .paperBackground()
        .sheet(item: $reorderRequest) { request in
            CalendarBookOrderEditor(date: request.date, books: request.books) { bookIDs in
                store.saveCalendarBookOrder(bookIDs, for: request.date)
            }
        }
        .sheet(isPresented: $isShowingDayEntries) {
            CalendarDayEntriesSheet(
                date: selectedDate,
                entries: entries(on: selectedDate),
                orderedBooks: books(on: selectedDate, applyingCategoryFilter: false),
                saveOrder: { bookIDs in
                    store.saveCalendarBookOrder(bookIDs, for: selectedDate)
                }
            )
        }
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

    var body: some View {
        GeometryReader { proxy in
            // 상단 필터를 남기고도 그리드가 화면을 꽉 채우도록 월별 행 높이를 계산합니다.
            let weekdayHeight: CGFloat = 18
            let headerHeight: CGFloat = 44
            let calendarCardInsets: CGFloat = 16
            let contentHeight = max(0, proxy.size.height - calendarCardInsets - headerHeight - GgotgalpiTheme.Spacing.control - weekdayHeight)
            let dayCellHeight = max(58, contentHeight / CGFloat(weekCount))

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
            .shadow(color: .black.opacity(0.07), radius: 12, y: 5)
        }
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
