import SwiftUI

struct BookDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: DemoStore
    let book: Book
    @State private var showingAddEntry = false

    private var bookEntries: [ReadingEntry] {
        store.entries(for: book.id)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    HStack(alignment: .top, spacing: 20) {
                        CoverPlaceholder(title: book.title, color: book.coverColor, size: CGSize(width: 112, height: 160))

                        VStack(alignment: .leading, spacing: 9) {
                            Text(book.title)
                                .font(.system(size: 25, weight: .medium, design: .serif))
                                .foregroundStyle(GgotgalpiTheme.ink)
                            Text(book.author)
                                .font(.subheadline)
                                .foregroundStyle(GgotgalpiTheme.secondaryInk)
                            Text(book.category.rawValue)
                                .font(.caption)
                                .foregroundStyle(GgotgalpiTheme.secondaryInk)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(GgotgalpiTheme.paperDeep)
                                .clipShape(Capsule())
                        }
                        Spacer()
                    }

                    HStack(spacing: 0) {
                        DetailStat(value: "\(bookEntries.count)", title: "감상 기록")
                        DetailStat(value: "\(Set(bookEntries.map(\.readingRound)).count)", title: "읽은 횟수")
                        DetailStat(value: bookEntries.isEmpty ? "-" : "\(bookEntries.map(\.pageTo).max() ?? 0)", title: "마지막 쪽")
                    }

                    Button {
                        showingAddEntry = true
                    } label: {
                        Label("감상 기록 남기기", systemImage: "pencil.line")
                            .font(.system(.headline, design: .serif))
                            .foregroundStyle(GgotgalpiTheme.paper)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(GgotgalpiTheme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }

                    SectionLabel(title: "감상 기록")

                    if bookEntries.isEmpty {
                        Text("아직 남긴 기록이 없어요.")
                            .font(.subheadline)
                            .foregroundStyle(GgotgalpiTheme.secondaryInk)
                    } else {
                        ForEach(bookEntries) { entry in
                            ReadingEntryRow(entry: entry)
                            if entry.id != bookEntries.last?.id { DividerLine() }
                        }
                    }
                }
                .padding(22)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("책 상세")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("닫기") { dismiss() }
                        .foregroundStyle(GgotgalpiTheme.secondaryInk)
                }
            }
            .sheet(isPresented: $showingAddEntry) {
                AddReadingEntryView(book: book)
            }
        }
        .paperBackground()
    }
}

struct DetailStat: View {
    let value: String
    let title: String

    var body: some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.system(size: 21, weight: .medium, design: .serif))
                .foregroundStyle(GgotgalpiTheme.ink)
            Text(title)
                .font(.caption2)
                .foregroundStyle(GgotgalpiTheme.secondaryInk)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ReadingEntryRow: View {
    let entry: ReadingEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text(entry.date.shortKoreanDate)
                    .font(.system(.subheadline, design: .serif))
                    .foregroundStyle(GgotgalpiTheme.ink)
                Spacer()
                Text("\(entry.readingRound)회독 · p.\(entry.pageFrom)-p.\(entry.pageTo)")
                    .font(.caption)
                    .foregroundStyle(GgotgalpiTheme.secondaryInk)
            }
            Text(entry.note)
                .font(.subheadline)
                .foregroundStyle(GgotgalpiTheme.secondaryInk)
                .lineSpacing(3)
        }
        .padding(.vertical, 3)
    }
}
