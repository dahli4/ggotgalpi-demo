import SwiftUI

struct ContentView: View {
    private enum Tab: Hashable {
        case calendar, bookshelf, record
    }

    @State private var selectedTab: Tab = .calendar

    var body: some View {
        GeometryReader { _ in
            ZStack {
                GgotgalpiTheme.paper.ignoresSafeArea()

                TabView(selection: $selectedTab) {
                    CalendarView()
                        .tabItem { Label("달력", systemImage: "calendar") }
                        .tag(Tab.calendar)

                    BookshelfView()
                        .tabItem { Label("책장", systemImage: "books.vertical") }
                        .tag(Tab.bookshelf)

                    MyRecordView()
                        .tabItem { Label("기록", systemImage: "quote.closing") }
                        .tag(Tab.record)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.keyboard)
    }
}

struct BookshelfView: View {
    @EnvironmentObject private var store: DemoStore
    @State private var selectedCategory: BookCategory = .all
    @State private var showingAddBook = false
    @State private var selectedBook: Book?

    private var visibleBooks: [Book] {
        guard selectedCategory != .all else { return store.books }
        return store.books.filter { $0.category == selectedCategory }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("꽃갈피")
                            .font(.system(size: 34, weight: .medium, design: .serif))
                            .foregroundStyle(GgotgalpiTheme.ink)

                        Text("읽은 문장과 마음을 오래 간직하는 곳")
                            .font(.subheadline)
                            .foregroundStyle(GgotgalpiTheme.secondaryInk)
                    }

                    CategoryPicker(selection: $selectedCategory)

                    SectionLabel(title: "나의 책장", actionTitle: "책 추가") {
                        showingAddBook = true
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 24) {
                        ForEach(visibleBooks) { book in
                            Button {
                                selectedBook = book
                            } label: {
                                BookCard(book: book, entryCount: store.entries(for: book.id).count)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(22)
            }
            .scrollIndicators(.hidden)
            .safeAreaPadding(.top, 8)
            .safeAreaPadding(.bottom, 96)
            .contentMargins(.bottom, 96, for: .scrollContent)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAddBook = true } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(GgotgalpiTheme.ink)
                    }
                }
            }
            .sheet(isPresented: $showingAddBook) {
                AddBookView()
            }
            .sheet(item: $selectedBook) { book in
                BookDetailView(book: book)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .paperBackground()
    }
}

struct CategoryPicker: View {
    @Binding var selection: BookCategory

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(BookCategory.allCases) { category in
                    Button(category.rawValue) {
                        withAnimation(.easeInOut(duration: 0.18)) { selection = category }
                    }
                    .font(.caption)
                    .foregroundStyle(selection == category ? GgotgalpiTheme.paper : GgotgalpiTheme.secondaryInk)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(selection == category ? GgotgalpiTheme.accent : GgotgalpiTheme.paperDeep)
                    .clipShape(Capsule())
                }
            }
        }
    }
}

struct BookCard: View {
    let book: Book
    let entryCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            CoverPlaceholder(title: book.title, color: book.coverColor, size: CGSize(width: 118, height: 168))
                .frame(maxWidth: .infinity)

            Text(book.title)
                .font(.system(.headline, design: .serif))
                .foregroundStyle(GgotgalpiTheme.ink)
                .lineLimit(1)

            HStack(spacing: 5) {
                Text(book.author)
                    .lineLimit(1)
                Text("·")
                Text("기록 \(entryCount)")
            }
            .font(.caption)
            .foregroundStyle(GgotgalpiTheme.secondaryInk)
        }
    }
}

struct CalendarView: View {
    @EnvironmentObject private var store: DemoStore
    @State private var monthOffset = 0
    @State private var selectedDate: Date? = Calendar.current.startOfDay(for: Date())
    @State private var selectedCategory: BookCategory = .all
    @State private var selectedEntryID: UUID?

    private var monthDate: Date {
        Calendar.current.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
    }

    private func entries(on date: Date) -> [ReadingEntry] {
        store.entries(on: date).filter { entry in
            guard let book = store.book(for: entry.bookID), !book.isHiddenFromCalendar else { return false }
            return selectedCategory == .all || book.category == selectedCategory
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("읽은 날들")
                            .font(.system(size: 31, weight: .medium, design: .serif))
                            .foregroundStyle(GgotgalpiTheme.ink)
                        Text("책 표지가 하루의 작은 꽃갈피가 됩니다")
                            .font(.subheadline)
                            .foregroundStyle(GgotgalpiTheme.secondaryInk)
                    }

                    CategoryPicker(selection: $selectedCategory)

                    HStack {
                        Button {
                            monthOffset -= 1
                            selectedDate = nil
                            selectedEntryID = nil
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        .buttonStyle(.plain)

                        Spacer()
                        Text(monthDate.formatted(.dateTime.year().month()))
                            .font(.system(.title3, design: .serif))
                            .foregroundStyle(GgotgalpiTheme.ink)
                        Spacer()

                        Button {
                            monthOffset += 1
                            selectedDate = nil
                            selectedEntryID = nil
                        } label: {
                            Image(systemName: "chevron.right")
                        }
                        .buttonStyle(.plain)
                    }
                    .foregroundStyle(GgotgalpiTheme.secondaryInk)

                    CalendarGrid(
                        monthDate: monthDate,
                        category: selectedCategory,
                        selectedDate: $selectedDate
                    )

                    DividerLine()

                    if let selectedDate {
                        DayEntriesView(date: selectedDate, entries: entries(on: selectedDate))
                    } else {
                        Text("날짜를 누르면 그날의 감상 기록이 보여요")
                            .font(.subheadline)
                            .foregroundStyle(GgotgalpiTheme.secondaryInk)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 18)
                    }
                }
                .padding(22)
            }
            .scrollIndicators(.hidden)
            .safeAreaPadding(.top, 8)
            .safeAreaPadding(.bottom, 96)
            .contentMargins(.bottom, 96, for: .scrollContent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .paperBackground()
    }

    @ViewBuilder
    private func DayEntriesView(date: Date, entries dayEntries: [ReadingEntry]) -> some View {
        let activeEntry = dayEntries.first { $0.id == selectedEntryID } ?? dayEntries.first

        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(title: date.shortKoreanDate)

            if dayEntries.isEmpty {
                Text("이날에는 아직 기록이 없어요.")
                    .font(.subheadline)
                    .foregroundStyle(GgotgalpiTheme.secondaryInk)
            } else {
                ForEach(dayEntries) { entry in
                    if let book = store.book(for: entry.bookID) {
                        Button {
                            selectedEntryID = entry.id
                        } label: {
                            HStack(spacing: 14) {
                                CoverPlaceholder(title: book.title, color: book.coverColor, size: CGSize(width: 42, height: 60))
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(book.title)
                                        .font(.system(.headline, design: .serif))
                                        .foregroundStyle(GgotgalpiTheme.ink)
                                    Text("p.\(entry.pageFrom) - p.\(entry.pageTo)")
                                        .font(.caption)
                                        .foregroundStyle(GgotgalpiTheme.secondaryInk)
                                }
                                Spacer()
                                Image(systemName: activeEntry?.id == entry.id ? "checkmark.circle.fill" : "chevron.right")
                                    .foregroundStyle(activeEntry?.id == entry.id ? GgotgalpiTheme.accent : GgotgalpiTheme.secondaryInk)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(10)
                        .background(activeEntry?.id == entry.id ? GgotgalpiTheme.paperDeep.opacity(0.72) : .clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }

                if let activeEntry,
                   let book = store.book(for: activeEntry.bookID) {
                    VStack(alignment: .leading, spacing: 9) {
                        Text("\(book.title)의 감상")
                            .font(.system(.headline, design: .serif))
                            .foregroundStyle(GgotgalpiTheme.ink)
                        Text(activeEntry.note)
                            .font(.subheadline)
                            .foregroundStyle(GgotgalpiTheme.secondaryInk)
                            .lineSpacing(4)
                    }
                    .padding(15)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(GgotgalpiTheme.paperDeep.opacity(0.58))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(GgotgalpiTheme.calendarLine.opacity(0.45), lineWidth: 0.7)
                    }
                    .padding(.top, 3)
                }
            }
        }
    }
}

struct CalendarGrid: View {
    @EnvironmentObject private var store: DemoStore
    let monthDate: Date
    let category: BookCategory
    @Binding var selectedDate: Date?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdaySymbols = ["일", "월", "화", "수", "목", "금", "토"]

    private var calendar: Calendar { Calendar.current }

    private var dates: [Date?] {
        guard let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate)),
              let range = calendar.range(of: .day, in: .month, for: firstDay) else { return [] }
        let leading = calendar.component(.weekday, from: firstDay) - 1
        let blanks = Array(repeating: Optional<Date>.none, count: leading)
        let days = range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: firstDay) }
        var result = blanks + days.map(Optional.some)
        while result.count % 7 != 0 { result.append(nil) }
        return result
    }

    private func entries(on date: Date) -> [ReadingEntry] {
        store.entries(on: date).filter { entry in
            guard let book = store.book(for: entry.bookID), !book.isHiddenFromCalendar else { return false }
            return category == .all || book.category == category
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2)
                        .foregroundStyle(GgotgalpiTheme.secondaryInk)
                        .frame(maxWidth: .infinity)
                }

                ForEach(Array(dates.enumerated()), id: \.offset) { index, date in
                    let isLastColumn = index % 7 == 6
                    let isLastRow = index >= dates.count - 7
                    if let date {
                        CalendarCellFrame(isLastColumn: isLastColumn, isLastRow: isLastRow) {
                            let dayEntries = entries(on: date)
                            CalendarDayCell(
                                date: date,
                                entries: dayEntries,
                                book: dayEntries.first.flatMap { store.book(for: $0.bookID) },
                                selectedDate: $selectedDate
                            )
                        }
                    } else {
                        CalendarCellFrame(isLastColumn: isLastColumn, isLastRow: isLastRow) {
                            Color.clear
                        }
                    }
                }
            }
        }
    }
}

struct CalendarCellFrame<Content: View>: View {
    let isLastColumn: Bool
    let isLastRow: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .frame(maxWidth: .infinity, minHeight: 78)
            .overlay(alignment: .trailing) {
                if !isLastColumn {
                    Rectangle()
                        .fill(GgotgalpiTheme.calendarLine)
                        .frame(width: 0.8)
                }
            }
            .overlay(alignment: .bottom) {
                if !isLastRow {
                    Rectangle()
                        .fill(GgotgalpiTheme.calendarLine)
                        .frame(height: 0.8)
                }
            }
    }
}

struct CalendarDayCell: View {
    let date: Date
    let entries: [ReadingEntry]
    let book: Book?
    @Binding var selectedDate: Date?

    var body: some View {
        Button {
            selectedDate = date
        } label: {
            VStack(spacing: 4) {
                Text(date.formatted(.dateTime.day()))
                    .font(.caption2)
                    .foregroundStyle(GgotgalpiTheme.ink)

                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(GgotgalpiTheme.paperDeep.opacity(entries.isEmpty ? 0.38 : 0.72))

                    if !entries.isEmpty, let book {
                        CoverPlaceholder(title: book.title, color: book.coverColor, size: CGSize(width: 27, height: 37))
                    } else if !entries.isEmpty {
                        Image(systemName: "book.closed")
                            .font(.caption2)
                            .foregroundStyle(GgotgalpiTheme.accent)
                    }
                }
                .frame(height: 38)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
        }
        .buttonStyle(.plain)
    }
}

struct MyRecordView: View {
    @EnvironmentObject private var store: DemoStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("나의 기록")
                            .font(.system(size: 31, weight: .medium, design: .serif))
                            .foregroundStyle(GgotgalpiTheme.ink)
                        Text("읽고, 남기고, 다시 꺼내 보는 문장들")
                            .font(.subheadline)
                            .foregroundStyle(GgotgalpiTheme.secondaryInk)
                    }

                    HStack(spacing: 12) {
                        StatCard(title: "기록한 날", value: "\(Set(store.entries.map { Calendar.current.startOfDay(for: $0.date) }).count)")
                        StatCard(title: "읽은 책", value: "\(store.books.count)")
                        StatCard(title: "감상문", value: "\(store.entries.count)")
                    }

                    SectionLabel(title: "최근 감상")
                    ForEach(store.entries.sorted { $0.date > $1.date }.prefix(5)) { entry in
                        if let book = store.book(for: entry.bookID) {
                            HStack(alignment: .top, spacing: 13) {
                                CoverPlaceholder(title: book.title, color: book.coverColor, size: CGSize(width: 42, height: 60))
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack {
                                        Text(book.title)
                                            .font(.system(.headline, design: .serif))
                                            .foregroundStyle(GgotgalpiTheme.ink)
                                        Spacer()
                                        Text(entry.date.shortKoreanDate)
                                            .font(.caption2)
                                            .foregroundStyle(GgotgalpiTheme.secondaryInk)
                                    }
                                    Text(entry.note)
                                        .font(.subheadline)
                                        .foregroundStyle(GgotgalpiTheme.secondaryInk)
                                        .lineLimit(3)
                                }
                            }
                            .padding(.vertical, 3)
                        }
                    }
                }
                .padding(22)
            }
            .scrollIndicators(.hidden)
            .safeAreaPadding(.top, 8)
            .safeAreaPadding(.bottom, 96)
            .contentMargins(.bottom, 96, for: .scrollContent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .paperBackground()
    }
}

struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(.system(size: 24, weight: .medium, design: .serif))
                .foregroundStyle(GgotgalpiTheme.ink)
            Text(title)
                .font(.caption)
                .foregroundStyle(GgotgalpiTheme.secondaryInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(GgotgalpiTheme.paperDeep.opacity(0.58))
        .overlay { RoundedRectangle(cornerRadius: 5).stroke(GgotgalpiTheme.line, lineWidth: 0.7) }
    }
}
