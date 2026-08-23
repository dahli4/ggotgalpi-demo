import SwiftUI

struct BookshelfView: View {
    @EnvironmentObject private var store: DemoStore
    @State private var selectedReadingStatus: ReadingStatus = .all
    @State private var selectedCategory: BookCategory = .all
    @State private var showingAddBook = false
    @State private var selectedBook: Book?
    @State private var isSearchExpanded = false
    @State private var searchQuery = ""
    @FocusState private var isSearchFieldFocused: Bool

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
                    if isSearchExpanded {
                        InlineUnifiedSearchView(query: $searchQuery)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

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
            // 툴바 슬롯의 고정 폭을 쓰지 않고, 화면의 좌우 여백 안에서 검색창을 직접 배치합니다.
            .safeAreaPadding(.top, 40)
            .overlay(alignment: .top) {
                bookshelfSearchControl
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, GgotgalpiTheme.Spacing.screen)
            }
            .sheet(isPresented: $showingAddBook) {
                AddBookView()
            }
            .sheet(item: $selectedBook) { book in
                BookDetailView(book: book)
            }
            .overlay(alignment: .bottomTrailing) {
                Button {
                    showingAddBook = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(GgotgalpiTheme.paper)
                        .frame(width: 52, height: 52)
                        .background(GgotgalpiTheme.accent)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.14), radius: 8, y: 4)
                }
                .accessibilityLabel("새 책 등록")
                // 하단 독의 오른쪽 빈 영역 바로 위에 떠 있도록 여백을 둡니다.
                .padding(.trailing, GgotgalpiTheme.Spacing.screen)
                .padding(.bottom, 76)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .paperBackground()
    }

    private var bookshelfSearchControl: some View {
        Group {
            if isSearchExpanded {
                HStack(spacing: 0) {
                    bookshelfSearchField
                        .layoutPriority(1)

                    bookshelfSearchButton
                }
                .frame(maxWidth: .infinity, minHeight: 40, maxHeight: 40)
            } else {
                bookshelfSearchButton
            }
        }
        .foregroundStyle(GgotgalpiTheme.ink)
        .background(Color.white.opacity(0.82), in: Capsule())
        .animation(.easeInOut(duration: 0.24), value: isSearchExpanded)
    }

    private var bookshelfSearchButton: some View {
            Button {
                if isSearchExpanded {
                    closeSearch()
                } else {
                    openSearch()
                }
            } label: {
                Image(systemName: "magnifyingglass")
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isSearchExpanded ? "검색 닫기" : "통합 검색")
    }

    private var bookshelfSearchField: some View {
        HStack(spacing: 6) {
            TextField("책, 감상문, 연도 또는 월", text: $searchQuery)
                .textFieldStyle(.plain)
                .font(.subheadline)
                .focused($isSearchFieldFocused)
                .submitLabel(.search)
                .frame(maxWidth: .infinity)

            if !searchQuery.isEmpty {
                Button {
                    searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(GgotgalpiTheme.secondaryInk)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("검색어 지우기")
            }
        }
        .padding(.horizontal, GgotgalpiTheme.Spacing.control)
        .frame(maxWidth: .infinity)
        .frame(height: 40)
        .transition(.scale(scale: 0.1, anchor: .trailing).combined(with: .opacity))
    }

    private func openSearch() {
        withAnimation(.easeInOut(duration: 0.24)) {
            isSearchExpanded = true
        }
        isSearchFieldFocused = true
    }

    private func closeSearch() {
        isSearchFieldFocused = false
        withAnimation(.easeInOut(duration: 0.24)) {
            isSearchExpanded = false
        }
        searchQuery = ""
    }
}

/// 책장 상단의 읽기 상태 탭입니다. 선택된 상태 안에서 아래 장르 탭이 다시 적용됩니다.
struct ReadingStatusPicker: View {
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

/// 달력 필터용 읽기 상태 탭입니다. 항목 사이의 세로선으로 선택지를 구분합니다.
struct ReadingStatusUnderlineTabs: View {
    @Binding var selection: ReadingStatus

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ReadingStatus.allCases) { status in
                Button {
                    selection = status
                } label: {
                    Text(status.rawValue)
                        .font(.subheadline.weight(selection == status ? .semibold : .regular))
                        .foregroundStyle(selection == status ? GgotgalpiTheme.ink : GgotgalpiTheme.secondaryInk)
                        .padding(.vertical, 7)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("읽기 상태: \(status.rawValue)")
                .accessibilityAddTraits(selection == status ? .isSelected : [])

                if status != ReadingStatus.allCases.last {
                    Rectangle()
                        .fill(GgotgalpiTheme.line.opacity(0.7))
                        .frame(width: 0.7, height: 18)
                }
            }
        }
    }
}

/// 달력 필터용 장르 탭입니다. 읽기 상태 탭과 같은 세로 구분선 스타일을 사용합니다.
struct CalendarCategoryTabs: View {
    @Binding var selection: BookCategory

    var body: some View {
        HStack(spacing: 0) {
            ForEach(BookCategory.allCases) { category in
                Button {
                    selection = category
                } label: {
                    Text(category.rawValue)
                        .font(.subheadline.weight(selection == category ? .semibold : .regular))
                        .foregroundStyle(selection == category ? GgotgalpiTheme.ink : GgotgalpiTheme.secondaryInk)
                        .padding(.vertical, 7)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("장르: \(category.rawValue)")
                .accessibilityAddTraits(selection == category ? .isSelected : [])

                if category != BookCategory.allCases.last {
                    Rectangle()
                        .fill(GgotgalpiTheme.line.opacity(0.7))
                        .frame(width: 0.7, height: 18)
                }
            }
        }
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
