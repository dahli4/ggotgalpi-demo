import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var store: DemoStore
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())

    private func entries(on date: Date) -> [ReadingEntry] {
        store.entries(on: date).filter { entry in
            store.book(for: entry.bookID)?.isHiddenFromCalendar == false
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: GgotgalpiTheme.Spacing.section) {
                    DatePicker(
                        "감상 날짜 선택",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "ko_KR"))
                    .tint(GgotgalpiTheme.accent)
                    .frame(maxWidth: .infinity)

                    DividerLine()
                    DayEntriesView(date: selectedDate, entries: entries(on: selectedDate))
                }
                .padding(.horizontal, GgotgalpiTheme.Spacing.screen)
                .padding(.bottom, GgotgalpiTheme.Spacing.section)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("캘린더")
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
    }

    @ViewBuilder
    private func DayEntriesView(date: Date, entries: [ReadingEntry]) -> some View {
        VStack(alignment: .leading, spacing: GgotgalpiTheme.Spacing.content) {
            SectionLabel(
                title: date.formatted(
                    .dateTime
                        .month()
                        .day()
                        .weekday(.wide)
                        .locale(Locale(identifier: "ko_KR"))
                )
            )

            if entries.isEmpty {
                ReadingEmptyState(
                    title: "아직 남긴 감상이 없어요",
                    message: "책장에서 작품을 고르고 이 날의 마음을 기록해 보세요."
                )
            } else {
                ForEach(entries) { entry in
                    if let book = store.book(for: entry.bookID) {
                        HStack(alignment: .top, spacing: GgotgalpiTheme.Spacing.control) {
                            BookColorMark(
                                title: book.title,
                                color: book.coverColor,
                                size: 44
                            )

                            VStack(alignment: .leading, spacing: GgotgalpiTheme.Spacing.compact) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(book.title)
                                        .font(.headline)
                                        .foregroundStyle(GgotgalpiTheme.ink)

                                    Spacer()

                                    Text("p.\(entry.pageFrom)-\(entry.pageTo)")
                                        .font(.caption)
                                        .foregroundStyle(GgotgalpiTheme.secondaryInk)
                                }

                                Text(entry.note)
                                    .font(.body)
                                    .foregroundStyle(GgotgalpiTheme.ink)
                                    .lineSpacing(4)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.vertical, 4)
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }
}
