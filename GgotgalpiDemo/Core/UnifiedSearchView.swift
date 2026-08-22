import SwiftUI

/// 책장과 달력에서 함께 쓰는 통합 검색 화면입니다.
/// 제목·작가·감상문뿐 아니라 연도와 월 표현도 감상 기록 날짜로 해석합니다.
struct UnifiedSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: DemoStore
    @State private var query = ""
    @State private var selectedBook: Book?
    @State private var showingAddBook = false

    private let calendar = Calendar.current

    private var normalizedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var dateFilter: SearchDateFilter? {
        let numbers = normalizedQuery
            .split(whereSeparator: { !$0.isNumber })
            .compactMap { Int($0) }

        let year = numbers.first(where: { (1000...9999).contains($0) })
        let month = numbers.last(where: { (1...12).contains($0) })

        if normalizedQuery.contains("년") {
            guard let year else { return nil }
            if normalizedQuery.contains("월"), let month {
                return .yearMonth(year: year, month: month)
            }
            return .year(year)
        }

        if normalizedQuery.contains("월"), let month {
            return year.map { .yearMonth(year: $0, month: month) } ?? .month(month)
        }

        if normalizedQuery.count == 4, let year, numbers.count == 1 {
            return .year(year)
        }

        return nil
    }

    private var textQuery: String {
        guard dateFilter != nil else { return normalizedQuery }

        let numbers = normalizedQuery
            .split(whereSeparator: { !$0.isNumber })
            .compactMap { Int($0) }

        return numbers.reduce(
            normalizedQuery.replacingOccurrences(of: "년", with: " ")
                .replacingOccurrences(of: "월", with: " ")
        ) { partial, number in
            partial.replacingOccurrences(of: String(number), with: " ")
        }
        .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var compactTextQuery: String {
        textQuery.removingWhitespaceAndNewlines
    }

    private var hasSearchTerm: Bool {
        !normalizedQuery.isEmpty
    }

    private var matchingEntries: [ReadingEntry] {
        store.entries
            .filter { entry in
                let matchesDate = dateFilter.map { $0.matches(entry.date, calendar: calendar) } ?? true
                return matchesDate && matches(entry: entry)
            }
            .sorted { $0.date > $1.date }
    }

    private var matchingBooks: [Book] {
        if dateFilter != nil {
            let bookIDs = Set(matchingEntries.map(\.bookID))
            return store.books.filter { bookIDs.contains($0.id) }
        }

        return store.books.filter(matches(book:))
    }

    private var entryMonthGroups: [SearchEntryMonthGroup] {
        let groupedEntries = Dictionary(grouping: matchingEntries) { entry in
            calendar.date(from: calendar.dateComponents([.year, .month], from: entry.date)) ?? entry.date
        }

        return groupedEntries
            .map { SearchEntryMonthGroup(month: $0.key, entries: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.month > $1.month }
    }

    var body: some View {
        NavigationStack {
            List {
                if !hasSearchTerm {
                    Section {
                        SearchGuideRow(icon: "text.magnifyingglass", title: "책과 기록을 함께 찾아보세요", message: "책 제목, 작가 이름, 감상문 내용을 입력할 수 있어요.")
                        SearchGuideRow(icon: "calendar", title: "날짜로도 찾을 수 있어요", message: "예: 2026년 · 2026년 8월 · 8월")
                    }

                    Section {
                        Button {
                            showingAddBook = true
                        } label: {
                            Label("새 책 직접 등록", systemImage: "plus.circle")
                                .foregroundStyle(GgotgalpiTheme.ink)
                        }
                    }
                } else if matchingBooks.isEmpty && matchingEntries.isEmpty {
                    Section {
                        ReadingEmptyState(
                            title: "검색 결과가 없어요",
                            message: "다른 제목, 감상문 문장, 또는 날짜로 찾아보세요."
                        )
                        .listRowBackground(Color.clear)
                    }

                    Section {
                        Button {
                            showingAddBook = true
                        } label: {
                            Label("새 책 직접 등록", systemImage: "plus.circle")
                                .foregroundStyle(GgotgalpiTheme.ink)
                        }
                    }
                } else {
                    if !matchingBooks.isEmpty {
                        Section(dateFilter == nil ? "등록된 책" : "해당 기간에 읽은 책") {
                            ForEach(matchingBooks) { book in
                                Button {
                                    selectedBook = book
                                } label: {
                                    SearchBookRow(book: book, entryCount: store.entries(for: book.id).count)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if !matchingEntries.isEmpty {
                        if case .month = dateFilter {
                            ForEach(entryMonthGroups) { group in
                                Section(group.title) {
                                    searchEntryRows(group.entries)
                                }
                            }
                        } else {
                            Section("감상 기록") {
                                searchEntryRows(matchingEntries)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(GgotgalpiTheme.paper)
            .navigationTitle("통합 검색")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "책, 감상문, 연도 또는 월 검색")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("닫기") { dismiss() }
                        .foregroundStyle(GgotgalpiTheme.secondaryInk)
                }
            }
            .sheet(item: $selectedBook) { book in
                BookDetailView(book: book)
            }
            .sheet(isPresented: $showingAddBook) {
                AddBookView()
            }
        }
        .paperBackground()
    }

    private func matches(book: Book) -> Bool {
        guard !textQuery.isEmpty else { return dateFilter != nil }
        let searchableText = [book.title, book.author, book.category.rawValue, book.readingStatus.rawValue]
            .joined(separator: " ")
        return matchesSearchText(searchableText)
    }

    private func matches(entry: ReadingEntry) -> Bool {
        guard !textQuery.isEmpty else { return true }
        guard let book = store.book(for: entry.bookID) else { return false }
        let searchableText = [book.title, book.author, entry.note]
            .joined(separator: " ")
        return matchesSearchText(searchableText)
    }

    private func matchesSearchText(_ searchableText: String) -> Bool {
        searchableText.localizedCaseInsensitiveContains(textQuery)
            || searchableText.removingWhitespaceAndNewlines.localizedCaseInsensitiveContains(compactTextQuery)
    }

    @ViewBuilder
    private func searchEntryRows(_ entries: [ReadingEntry]) -> some View {
        ForEach(entries) { entry in
            if let book = store.book(for: entry.bookID) {
                Button {
                    selectedBook = book
                } label: {
                    SearchEntryRow(book: book, entry: entry)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private extension String {
    var removingWhitespaceAndNewlines: String {
        unicodeScalars.filter { !CharacterSet.whitespacesAndNewlines.contains($0) }
            .map(String.init)
            .joined()
    }
}

private enum SearchDateFilter: Equatable {
    case year(Int)
    case yearMonth(year: Int, month: Int)
    case month(Int)

    func matches(_ date: Date, calendar: Calendar) -> Bool {
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)

        switch self {
        case .year(let targetYear):
            return year == targetYear
        case .yearMonth(let targetYear, let targetMonth):
            return year == targetYear && month == targetMonth
        case .month(let targetMonth):
            return month == targetMonth
        }
    }
}

private struct SearchEntryMonthGroup: Identifiable {
    let month: Date
    let entries: [ReadingEntry]

    var id: Date { month }

    var title: String {
        month.formatted(.dateTime.year().month().locale(Locale(identifier: "ko_KR")))
    }
}

private struct SearchGuideRow: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(GgotgalpiTheme.accent)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(GgotgalpiTheme.ink)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(GgotgalpiTheme.secondaryInk)
            }
        }
        .padding(.vertical, 3)
    }
}

private struct SearchBookRow: View {
    let book: Book
    let entryCount: Int

    var body: some View {
        HStack(spacing: 12) {
            BookColorMark(title: book.title, color: book.coverColor, size: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text(book.title)
                    .font(.headline)
                    .foregroundStyle(GgotgalpiTheme.ink)
                Text(book.author)
                    .font(.subheadline)
                    .foregroundStyle(GgotgalpiTheme.secondaryInk)
                Text("감상 \(entryCount)개 · \(book.category.rawValue)")
                    .font(.caption)
                    .foregroundStyle(GgotgalpiTheme.secondaryInk)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(GgotgalpiTheme.secondaryInk)
        }
        .contentShape(Rectangle())
    }
}

private struct SearchEntryRow: View {
    let book: Book
    let entry: ReadingEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                BookColorMark(title: book.title, color: book.coverColor, size: 40)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(book.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(GgotgalpiTheme.ink)
                        Spacer()
                        Text(entry.date.shortKoreanDate)
                            .font(.caption)
                            .foregroundStyle(GgotgalpiTheme.secondaryInk)
                    }
                    Text("p.\(entry.pageFrom)-\(entry.pageTo) · \(entry.readingRound)회독")
                        .font(.caption)
                        .foregroundStyle(GgotgalpiTheme.secondaryInk)
                    Text(entry.note)
                        .font(.subheadline)
                        .foregroundStyle(GgotgalpiTheme.secondaryInk)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
