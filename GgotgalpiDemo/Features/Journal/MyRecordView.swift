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
