import Foundation
import SwiftUI

enum BookCategory: String, CaseIterable, Identifiable {
    case all = "전체"
    case literature = "문학"
    case nonfiction = "비문학"
    case study = "학습"

    var id: String { rawValue }
}

struct Book: Identifiable, Hashable {
    let id: UUID
    var title: String
    var author: String
    var category: BookCategory
    var coverColor: Color
    var isHiddenFromCalendar: Bool

    init(
        id: UUID = UUID(),
        title: String,
        author: String,
        category: BookCategory,
        coverColor: Color,
        isHiddenFromCalendar: Bool = false
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.category = category
        self.coverColor = coverColor
        self.isHiddenFromCalendar = isHiddenFromCalendar
    }
}

struct ReadingEntry: Identifiable, Hashable {
    let id: UUID
    let bookID: UUID
    var date: Date
    var pageFrom: Int
    var pageTo: Int
    var note: String
    var readingRound: Int

    init(
        id: UUID = UUID(),
        bookID: UUID,
        date: Date,
        pageFrom: Int,
        pageTo: Int,
        note: String,
        readingRound: Int
    ) {
        self.id = id
        self.bookID = bookID
        self.date = date
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

    init() {
        let littlePrince = Book(
            title: "어린 왕자",
            author: "앙투안 드 생텍쥐페리",
            category: .literature,
            coverColor: Color(red: 0.55, green: 0.65, blue: 0.61)
        )
        let quietReading = Book(
            title: "아주 작은 습관",
            author: "제임스 클리어",
            category: .nonfiction,
            coverColor: Color(red: 0.66, green: 0.56, blue: 0.45)
        )
        let notes = Book(
            title: "생각의 지도",
            author: "리처드 니스벳",
            category: .study,
            coverColor: Color(red: 0.42, green: 0.48, blue: 0.58),
            isHiddenFromCalendar: true
        )

        books = [littlePrince, quietReading, notes]

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        entries = [
            ReadingEntry(bookID: littlePrince.id, date: today, pageFrom: 1, pageTo: 34, note: "어른이 된다는 건 중요한 것을 잊는 일일까. 작은 별의 풍경이 오래 남았다.", readingRound: 1),
            ReadingEntry(bookID: quietReading.id, date: calendar.date(byAdding: .day, value: -2, to: today) ?? today, pageFrom: 24, pageTo: 58, note: "작은 행동을 반복하는 일이 결국 나를 만든다는 문장이 좋았다.", readingRound: 1),
            ReadingEntry(bookID: littlePrince.id, date: calendar.date(byAdding: .day, value: -5, to: today) ?? today, pageFrom: 35, pageTo: 72, note: "길들인다는 것과 관계를 맺는다는 것에 대해 생각했다.", readingRound: 1),
            ReadingEntry(bookID: littlePrince.id, date: calendar.date(byAdding: .day, value: -7, to: today) ?? today, pageFrom: 1, pageTo: 20, note: "두 번째로 읽으니 처음과 다른 문장이 보인다.", readingRound: 2)
        ]
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

    func addBook(title: String, author: String, category: BookCategory) {
        let colors: [Color] = [
            Color(red: 0.57, green: 0.62, blue: 0.54),
            Color(red: 0.64, green: 0.53, blue: 0.48),
            Color(red: 0.48, green: 0.53, blue: 0.63)
        ]
        books.append(Book(title: title, author: author, category: category, coverColor: colors[books.count % colors.count]))
    }

    func addEntry(bookID: UUID, date: Date, pageFrom: Int, pageTo: Int, note: String, readingRound: Int) {
        entries.append(ReadingEntry(bookID: bookID, date: date, pageFrom: pageFrom, pageTo: pageTo, note: note, readingRound: readingRound))
    }
}

extension Date {
    var shortKoreanDate: String {
        formatted(.dateTime.year().month().day())
    }
}
