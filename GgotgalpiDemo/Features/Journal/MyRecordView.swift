import SwiftUI

struct MyRecordView: View {
    @EnvironmentObject private var store: DemoStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var recentEntries: [ReadingEntry] {
        Array(store.entries.sorted { $0.date > $1.date }.prefix(5))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: GgotgalpiTheme.Spacing.section) {
                    if dynamicTypeSize.isAccessibilitySize {
                        VStack(spacing: GgotgalpiTheme.Spacing.control) {
                            stats
                        }
                    } else {
                        HStack(spacing: GgotgalpiTheme.Spacing.control) {
                            stats
                        }
                    }

                    SectionLabel(title: "최근 감상")

                    ForEach(recentEntries) { entry in
                        if let book = store.book(for: entry.bookID) {
                            HStack(alignment: .top, spacing: GgotgalpiTheme.Spacing.control) {
                                BookColorMark(
                                    title: book.title,
                                    color: book.coverColor,
                                    size: 42
                                )

                                VStack(alignment: .leading, spacing: GgotgalpiTheme.Spacing.compact) {
                                    HStack {
                                        Text(book.title)
                                            .font(.headline)
                                            .foregroundStyle(GgotgalpiTheme.ink)

                                        Spacer()

                                        Text(entry.date.shortKoreanDate)
                                            .font(.caption2)
                                            .foregroundStyle(GgotgalpiTheme.secondaryInk)
                                    }

                                    Text(entry.note)
                                        .font(.subheadline)
                                        .foregroundStyle(GgotgalpiTheme.secondaryInk)
                                        .fixedSize(horizontal: false, vertical: true)

                                    if !entry.favoriteSentence.isEmpty {
                                        Text("“\(entry.favoriteSentence)”")
                                            .font(.caption)
                                            .foregroundStyle(GgotgalpiTheme.ink)
                                            .italic()
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            .padding(.vertical, GgotgalpiTheme.Spacing.compact)

                            if entry.id != recentEntries.last?.id {
                                DividerLine()
                            }
                        }
                    }
                }
                .padding(.horizontal, GgotgalpiTheme.Spacing.screen)
                .padding(.vertical, GgotgalpiTheme.Spacing.content)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("나의 감상")
        }
        .paperBackground()
    }

    @ViewBuilder
    private var stats: some View {
        StatCard(
            title: "기록한 날",
            value: "\(Set(store.entries.map { Calendar.current.startOfDay(for: $0.date) }).count)"
        )
        StatCard(title: "읽은 책", value: "\(store.books.count)")
        StatCard(title: "감상문", value: "\(store.entries.count)")
    }
}

struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: GgotgalpiTheme.Spacing.compact) {
            Text(value)
                .font(.title2.weight(.semibold))
                .foregroundStyle(GgotgalpiTheme.ink)

            Text(title)
                .font(.caption)
                .foregroundStyle(GgotgalpiTheme.secondaryInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, GgotgalpiTheme.Spacing.compact)
    }
}

struct FavoriteSentencesView: View {
    @EnvironmentObject private var store: DemoStore

    private var savedEntries: [ReadingEntry] {
        store.entries
            .filter { !$0.favoriteSentence.isEmpty }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GgotgalpiTheme.Spacing.section) {
                if savedEntries.isEmpty {
                    ReadingEmptyState(
                        title: "아직 모은 문장이 없어요",
                        message: "감상 기록을 남길 때 마음에 드는 문장을 함께 저장해 보세요."
                    )
                } else {
                    Text("\(savedEntries.count)개의 문장")
                        .font(.subheadline)
                        .foregroundStyle(GgotgalpiTheme.secondaryInk)

                    LazyVStack(spacing: 0) {
                        ForEach(savedEntries) { entry in
                            if let book = store.book(for: entry.bookID) {
                                FavoriteSentenceRow(book: book, entry: entry)

                                if entry.id != savedEntries.last?.id {
                                    DividerLine()
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, GgotgalpiTheme.Spacing.screen)
            .padding(.vertical, GgotgalpiTheme.Spacing.content)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("마음에 드는 문장")
        .navigationBarTitleDisplayMode(.inline)
        .paperBackground()
    }
}

struct FavoriteSentencesShortcut: View {
    let sentenceCount: Int

    var body: some View {
        HStack(spacing: GgotgalpiTheme.Spacing.control) {
            Image(systemName: "quote.opening")
                .font(.title3.weight(.semibold))
                .foregroundStyle(GgotgalpiTheme.accent)
                .frame(width: 38, height: 38)
                .background(GgotgalpiTheme.paperDeep, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text("마음에 드는 문장")
                    .font(.headline)
                    .foregroundStyle(GgotgalpiTheme.ink)

                Text(sentenceCount == 0 ? "기억하고 싶은 문장을 모아보세요." : "\(sentenceCount)개의 문장을 모아두었어요.")
                    .font(.caption)
                    .foregroundStyle(GgotgalpiTheme.secondaryInk)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(GgotgalpiTheme.secondaryInk)
        }
        .padding(GgotgalpiTheme.Spacing.content)
        .background(Color.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("마음에 드는 문장 모음")
        .accessibilityValue("\(sentenceCount)개")
    }
}

struct FavoriteSentenceRow: View {
    let book: Book
    let entry: ReadingEntry

    var body: some View {
        HStack(alignment: .top, spacing: GgotgalpiTheme.Spacing.control) {
            BookColorMark(title: book.title, color: book.coverColor, size: 42)

            VStack(alignment: .leading, spacing: GgotgalpiTheme.Spacing.compact) {
                HStack(alignment: .firstTextBaseline) {
                    Text(book.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(GgotgalpiTheme.ink)

                    Spacer(minLength: 8)

                    Text(entry.date.shortKoreanDate)
                        .font(.caption2)
                        .foregroundStyle(GgotgalpiTheme.secondaryInk)
                }

                Text("“\(entry.favoriteSentence)”")
                    .font(.subheadline)
                    .foregroundStyle(GgotgalpiTheme.ink)
                    .italic()
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, GgotgalpiTheme.Spacing.control)
    }
}
