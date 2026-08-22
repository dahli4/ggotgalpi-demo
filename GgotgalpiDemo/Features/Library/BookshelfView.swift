import SwiftUI

struct BookshelfView: View {
    @EnvironmentObject private var store: DemoStore
    @State private var selectedReadingStatus: ReadingStatus = .all
    @State private var selectedCategory: BookCategory = .all
    @State private var showingAddBook = false
    @State private var selectedBook: Book?
    @State private var isShowingSearch = false

    private var visibleBooks: [Book] {
        store.books.filter { book in
            let matchesStatus = selectedReadingStatus == .all || book.readingStatus == selectedReadingStatus
            let matchesCategory = selectedCategory == .all || book.category == selectedCategory
            return matchesStatus && matchesCategory
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: GgotgalpiTheme.Spacing.section) {
                    ReadingStatusPicker(selection: $selectedReadingStatus)
                    CategoryUnderlineTabs(selection: $selectedCategory)
                    SectionLabel(title: "나의 책장")

                    LazyVStack(spacing: 0) {
                        ForEach(visibleBooks) { book in
                            Button {
                                selectedBook = book
                            } label: {
                                BookCard(book: book, entryCount: store.entries(for: book.id).count)
                            }
                            .buttonStyle(.plain)

                            if book.id != visibleBooks.last?.id {
                                DividerLine()
                            }
                        }
                    }
                }
                .padding(.horizontal, GgotgalpiTheme.Spacing.screen)
                .padding(.vertical, GgotgalpiTheme.Spacing.content)
            }
            .scrollIndicators(.hidden)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        isShowingSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(GgotgalpiTheme.ink)
                    }
                    .accessibilityLabel("통합 검색")

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
            .sheet(isPresented: $isShowingSearch) {
                UnifiedSearchView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .paperBackground()
    }
}

/// 책장 상단의 읽기 상태 탭입니다. 선택된 상태 안에서 아래 장르 탭이 다시 적용됩니다.
private struct ReadingStatusPicker: View {
    @Binding var selection: ReadingStatus

    var body: some View {
        Picker("읽기 상태", selection: $selection) {
            ForEach(ReadingStatus.allCases) { status in
                Text(status.rawValue).tag(status)
            }
        }
        .pickerStyle(.segmented)
    }
}

/// 상태 탭보다 한 단계 낮은 장르 필터입니다. 별도 회색 컨트롤 대신 가벼운 텍스트 탭으로 표현합니다.
struct CategoryUnderlineTabs: View {
    @Binding var selection: BookCategory

    var body: some View {
        HStack(spacing: 0) {
            ForEach(BookCategory.allCases) { category in
                Button {
                    selection = category
                } label: {
                    VStack(spacing: 7) {
                        Text(category.rawValue)
                            .font(.subheadline.weight(selection == category ? .semibold : .regular))
                            .foregroundStyle(selection == category ? GgotgalpiTheme.ink : GgotgalpiTheme.secondaryInk)

                        Capsule()
                            .fill(selection == category ? GgotgalpiTheme.accent : .clear)
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("장르: \(category.rawValue)")
                .accessibilityAddTraits(selection == category ? .isSelected : [])
            }
        }
        .padding(.top, 2)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(GgotgalpiTheme.line.opacity(0.55))
                .frame(height: 0.6)
        }
    }
}

struct CategoryPicker: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Binding var selection: BookCategory

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            Picker("분야: \(selection.rawValue)", selection: $selection) {
                ForEach(BookCategory.allCases) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        } else {
            Picker("분야", selection: $selection) {
                ForEach(BookCategory.allCases) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

struct BookCard: View {
    let book: Book
    let entryCount: Int

    var body: some View {
        HStack(spacing: GgotgalpiTheme.Spacing.control) {
            BookColorMark(title: book.title, color: book.coverColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .foregroundStyle(GgotgalpiTheme.ink)

                Text(book.author)
                    .font(.subheadline)
                    .foregroundStyle(GgotgalpiTheme.secondaryInk)

                Text("감상 \(entryCount)개")
                    .font(.caption)
                    .foregroundStyle(GgotgalpiTheme.secondaryInk)
            }
            .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(GgotgalpiTheme.secondaryInk)
        }
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .contentShape(Rectangle())
    }
}
