import Foundation
import SwiftUI

enum BookCategory: String, CaseIterable, Identifiable {
    case all = "전체"
    case literature = "문학"
    case nonfiction = "비문학"
    case study = "학습"

    var id: String { rawValue }
}

/// 책장의 첫 번째 분류 기준입니다. 상태를 먼저 고르고, 그 안에서 장르를 다시 고릅니다.
enum ReadingStatus: String, CaseIterable, Identifiable {
    case all = "모두"
    case wantToRead = "보고 싶은"
    case finished = "읽은"
    case reading = "읽고 있는"

    var id: String { rawValue }
}

struct Book: Identifiable, Hashable {
    let id: UUID
    var title: String
    var author: String
    var publisher: String
    var category: BookCategory
    var readingStatus: ReadingStatus
    var coverColor: Color
    var isHiddenFromCalendar: Bool

    init(
        id: UUID = UUID(),
        title: String,
        author: String,
        publisher: String = "",
        category: BookCategory,
        readingStatus: ReadingStatus = .wantToRead,
        coverColor: Color,
        isHiddenFromCalendar: Bool = false
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.publisher = publisher
        self.category = category
        self.readingStatus = readingStatus
        self.coverColor = coverColor
        self.isHiddenFromCalendar = isHiddenFromCalendar
    }
}

struct ReadingEntry: Identifiable, Hashable {
    let id: UUID
    let bookID: UUID
    var date: Date
    /// 같은 날짜 안에서 표지의 기본 앞뒤 순서를 정하는 감상 작성 시각입니다.
    var createdAt: Date
    var pageFrom: Int
    var pageTo: Int
    var note: String
    var readingRound: Int

    init(
        id: UUID = UUID(),
        bookID: UUID,
        date: Date,
        createdAt: Date = Date(),
        pageFrom: Int,
        pageTo: Int,
        note: String,
        readingRound: Int
    ) {
        self.id = id
        self.bookID = bookID
        self.date = date
        self.createdAt = createdAt
        self.pageFrom = pageFrom
        self.pageTo = pageTo
        self.note = note
        self.readingRound = readingRound
    }
}

@MainActor
final class DemoStore: ObservableObject {
    @Published var books: [Book] = []
    @Published var entries: [ReadingEntry] = []
    @Published private var calendarBookOrders: [String: [UUID]] = [:]

    private let calendarBookOrdersKey = "ggotgalpi.calendar-book-orders.v1"

    init() {
        let littlePrince = Book(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            title: "어린 왕자",
            author: "앙투안 드 생텍쥐페리",
            category: .literature,
            readingStatus: .reading,
            coverColor: Color(red: 0.55, green: 0.65, blue: 0.61)
        )
        let quietReading = Book(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            title: "아주 작은 습관",
            author: "제임스 클리어",
            category: .nonfiction,
            readingStatus: .finished,
            coverColor: Color(red: 0.66, green: 0.56, blue: 0.45)
        )
        let notes = Book(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            title: "생각의 지도",
            author: "리처드 니스벳",
            category: .study,
            readingStatus: .wantToRead,
            coverColor: Color(red: 0.42, green: 0.48, blue: 0.58),
            isHiddenFromCalendar: true
        )

        books = [littlePrince, quietReading, notes]

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let now = Date()
        entries = [
            ReadingEntry(bookID: littlePrince.id, date: today, createdAt: now.addingTimeInterval(-180), pageFrom: 1, pageTo: 34, note: "어른이 된다는 건 중요한 것을 잊는 일일까. 작은 별의 풍경이 오래 남았다.", readingRound: 1),
            ReadingEntry(bookID: quietReading.id, date: today, createdAt: now, pageFrom: 24, pageTo: 58, note: "작은 행동을 반복하는 일이 결국 나를 만든다는 문장이 좋았다.", readingRound: 1),
            ReadingEntry(bookID: littlePrince.id, date: calendar.date(byAdding: .day, value: -5, to: today) ?? today, createdAt: now.addingTimeInterval(-14_400), pageFrom: 35, pageTo: 72, note: "길들인다는 것과 관계를 맺는다는 것에 대해 생각했다.", readingRound: 1),
            ReadingEntry(bookID: littlePrince.id, date: calendar.date(byAdding: .day, value: -7, to: today) ?? today, createdAt: now.addingTimeInterval(-28_800), pageFrom: 1, pageTo: 20, note: "두 번째로 읽으니 처음과 다른 문장이 보인다.", readingRound: 2)
        ]

        loadCalendarBookOrders()
    }

    func book(for id: UUID) -> Book? {
        books.first { $0.id == id }
    }

    func entries(for bookID: UUID) -> [ReadingEntry] {
        entries.filter { $0.bookID == bookID }.sorted { $0.date > $1.date }
    }

    func entries(on date: Date) -> [ReadingEntry] {
        let calendar = Calendar.current
        return entries.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }

    func addBook(title: String, author: String, publisher: String = "", category: BookCategory) {
        let colors: [Color] = [
            Color(red: 0.57, green: 0.62, blue: 0.54),
            Color(red: 0.64, green: 0.53, blue: 0.48),
            Color(red: 0.48, green: 0.53, blue: 0.63)
        ]
        books.append(
            Book(
                title: title,
                author: author,
                publisher: publisher,
                category: category,
                coverColor: colors[books.count % colors.count]
            )
        )
    }

    func addEntry(bookID: UUID, date: Date, pageFrom: Int, pageTo: Int, note: String, readingRound: Int) {
        entries.append(ReadingEntry(bookID: bookID, date: date, pageFrom: pageFrom, pageTo: pageTo, note: note, readingRound: readingRound))
    }

    func updateEntry(id: UUID, date: Date, pageFrom: Int, pageTo: Int, note: String, readingRound: Int) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[index].date = date
        entries[index].pageFrom = pageFrom
        entries[index].pageTo = pageTo
        entries[index].note = note
        entries[index].readingRound = readingRound
    }

    func markBookAsFinished(id: UUID) {
        guard let index = books.firstIndex(where: { $0.id == id }) else { return }
        books[index].readingStatus = .finished
    }

    func updateBook(
        id: UUID,
        title: String,
        author: String,
        publisher: String,
        category: BookCategory,
        readingStatus: ReadingStatus,
        isHiddenFromCalendar: Bool
    ) {
        guard let index = books.firstIndex(where: { $0.id == id }) else { return }
        books[index].title = title
        books[index].author = author
        books[index].publisher = publisher
        books[index].category = category
        books[index].readingStatus = readingStatus
        books[index].isHiddenFromCalendar = isHiddenFromCalendar
    }

    /// 사용자가 정한 순서를 먼저 유지하고, 새로 생긴 작품은 그 뒤에 덧붙입니다.
    func orderedBookIDs(for date: Date, defaultOrder: [UUID]) -> [UUID] {
        let dateKey = calendarDateKey(for: date)
        guard let savedOrder = calendarBookOrders[dateKey] else { return defaultOrder }

        let validSavedOrder = savedOrder.filter { defaultOrder.contains($0) }
        let newBookIDs = defaultOrder.filter { !validSavedOrder.contains($0) }
        return validSavedOrder + newBookIDs
    }

    func saveCalendarBookOrder(_ bookIDs: [UUID], for date: Date) {
        calendarBookOrders[calendarDateKey(for: date)] = bookIDs
        guard let encoded = try? JSONEncoder().encode(calendarBookOrders) else { return }
        UserDefaults.standard.set(encoded, forKey: calendarBookOrdersKey)
    }

    private func loadCalendarBookOrders() {
        guard
            let data = UserDefaults.standard.data(forKey: calendarBookOrdersKey),
            let savedOrders = try? JSONDecoder().decode([String: [UUID]].self, from: data)
        else { return }
        calendarBookOrders = savedOrders
    }

    private func calendarDateKey(for date: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }
}

extension Date {
    var shortKoreanDate: String {
        formatted(
            .dateTime
                .year()
                .month()
                .day()
                .locale(Locale(identifier: "ko_KR"))
        )
    }
}
