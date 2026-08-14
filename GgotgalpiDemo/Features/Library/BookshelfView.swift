import SwiftUI

struct BookshelfView: View {
    @EnvironmentObject private var store: DemoStore
    @State private var selectedCategory: BookCategory = .all
    @State private var showingAddBook = false
    @State private var selectedBook: Book?

    private var visibleBooks: [Book] {
        guard selectedCategory != .all else { return store.books }
        return store.books.filter { $0.category == selectedCategory }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: GgotgalpiTheme.Spacing.section) {
                    CategoryPicker(selection: $selectedCategory)
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
            .navigationTitle("책장")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .paperBackground()
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
