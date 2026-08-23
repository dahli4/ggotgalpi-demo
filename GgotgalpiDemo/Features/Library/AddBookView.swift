import SwiftUI

struct AddBookView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: DemoStore
    @State private var title = ""
    @State private var author = ""
    @State private var publisher = ""
    @State private var category: BookCategory = .literature

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("책 제목", text: $title)
                    TextField("작가", text: $author)
                    TextField("출판사", text: $publisher)
                    Picker("분야", selection: $category) {
                        ForEach(BookCategory.allCases.filter { $0 != .all }) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                } header: {
                    Text("새 책")
                } footer: {
                    Text("데모에서는 책마다 구분 색상을 자동으로 지정합니다.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(GgotgalpiTheme.paper)
            .navigationTitle("책 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        store.addBook(title: title, author: author, publisher: publisher, category: category)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
        .paperBackground()
    }
}

struct EditBookView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: DemoStore
    let book: Book
    @State private var title: String
    @State private var author: String
    @State private var publisher: String
    @State private var category: BookCategory
    @State private var readingStatus: ReadingStatus
    @State private var isHiddenFromCalendar: Bool

    init(book: Book) {
        self.book = book
        _title = State(initialValue: book.title)
        _author = State(initialValue: book.author)
        _publisher = State(initialValue: book.publisher)
        _category = State(initialValue: book.category)
        _readingStatus = State(initialValue: book.readingStatus)
        _isHiddenFromCalendar = State(initialValue: book.isHiddenFromCalendar)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("책 정보") {
                    TextField("책 제목", text: $title)
                    TextField("작가", text: $author)
                    TextField("출판사", text: $publisher)
                    Picker("분야", selection: $category) {
                        ForEach(BookCategory.allCases.filter { $0 != .all }) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }

                Section("읽기 설정") {
                    Picker("읽기 상태", selection: $readingStatus) {
                        ForEach(ReadingStatus.allCases.filter { $0 != .all }) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    Toggle("달력에서 숨기기", isOn: $isHiddenFromCalendar)
                }
            }
            .scrollContentBackground(.hidden)
            .background(GgotgalpiTheme.paper)
            .navigationTitle("책 정보 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        store.updateBook(
                            id: book.id,
                            title: title,
                            author: author,
                            publisher: publisher,
                            category: category,
                            readingStatus: readingStatus,
                            isHiddenFromCalendar: isHiddenFromCalendar
                        )
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.large])
        .paperBackground()
    }
}

struct AddReadingEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: DemoStore
    let book: Book
    let editingEntry: ReadingEntry?
    @State private var date = Date()
    @State private var pageFrom = ""
    @State private var pageTo = ""
    @State private var note = ""
    @State private var readingRound = 0
    @State private var hasFinishedReadingRound = false
    @State private var hasInitializedValues = false

    private var mostRecentPage: Int? {
        store.entries(for: book.id)
            .max { $0.createdAt < $1.createdAt }?
            .pageTo
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("읽은 날짜", selection: $date, displayedComponents: .date)
                    Stepper("\(readingRound)회독", value: $readingRound, in: 0...99)
                }

                Section("읽은 구간") {
                    HStack {
                        TextField("시작", text: $pageFrom)
                            .keyboardType(.numberPad)
                        Text("쪽부터")
                            .foregroundStyle(GgotgalpiTheme.secondaryInk)
                        TextField("끝", text: $pageTo)
                            .keyboardType(.numberPad)
                        Text("쪽까지")
                            .foregroundStyle(GgotgalpiTheme.secondaryInk)
                    }
                }

                Section("감상") {
                    TextEditor(text: $note)
                        .frame(minHeight: 130)
                }

                Section {
                    Button {
                        hasFinishedReadingRound.toggle()
                    } label: {
                        HStack(spacing: GgotgalpiTheme.Spacing.control) {
                            Image(systemName: hasFinishedReadingRound ? "checkmark.square.fill" : "square")
                                .font(.title3)
                            Text("이번 회독을 마치셨나요?")
                            Spacer()
                        }
                        .foregroundStyle(GgotgalpiTheme.ink)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("이번 회독을 마치셨나요?")
                    .accessibilityValue(hasFinishedReadingRound ? "선택됨" : "선택되지 않음")
                }
            }
            .scrollContentBackground(.hidden)
            .background(GgotgalpiTheme.paper)
            .navigationTitle(editingEntry == nil ? "감상 기록" : "감상 기록 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(editingEntry == nil ? "기록" : "저장") {
                        if let editingEntry {
                            store.updateEntry(
                                id: editingEntry.id,
                                date: date,
                                pageFrom: Int(pageFrom) ?? 0,
                                pageTo: Int(pageTo) ?? 0,
                                note: note.isEmpty ? "새로운 감상을 기록했어요." : note,
                                readingRound: readingRound
                            )
                        } else {
                            store.addEntry(
                                bookID: book.id,
                                date: date,
                                pageFrom: Int(pageFrom) ?? 0,
                                pageTo: Int(pageTo) ?? 0,
                                note: note.isEmpty ? "새로운 감상을 기록했어요." : note,
                                readingRound: readingRound
                            )
                        }

                        if hasFinishedReadingRound {
                            store.markBookAsFinished(id: book.id)
                        }
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
        .paperBackground()
        .onAppear {
            guard
                !hasInitializedValues
            else { return }

            hasInitializedValues = true
            if let editingEntry {
                date = editingEntry.date
                pageFrom = String(editingEntry.pageFrom)
                pageTo = String(editingEntry.pageTo)
                note = editingEntry.note
                readingRound = editingEntry.readingRound
                hasFinishedReadingRound = book.readingStatus == .finished
            } else if book.readingStatus == .reading, let mostRecentPage {
                pageFrom = String(mostRecentPage)
            }
        }
    }
}
