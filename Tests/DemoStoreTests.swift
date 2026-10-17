import Foundation
import SwiftData

private final class MemoryCloud: NSObject, SyncedSettingsCloudStore {
    var values: [String: Any] = [:]
    func object(forKey key: String) -> Any? { values[key] }
    func set(_ value: Any?, forKey key: String) { values[key] = value }
    func synchronize() -> Bool { true }
}

private struct StoreFailure: Error {
    let message: String
}

@main
@MainActor
struct DemoStoreTests {
    static func main() throws {
        let suite = "DemoStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let cloud = MemoryCloud()
        let notifications = NotificationCenter()
        let settings = SyncedSettings(
            cloud: cloud, defaults: defaults, notificationCenter: notifications
        )
        let schema = Schema([Book.self, ReadingEntry.self])
        let configuration = ModelConfiguration(
            schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let store = DemoStore(modelContext: container.mainContext, settings: settings)

        func check(_ condition: Bool, _ message: String) throws {
            guard condition else { throw StoreFailure(message: message) }
        }
        func externalChange() {
            notifications.post(
                name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                object: cloud,
                userInfo: [
                    NSUbiquitousKeyValueStoreChangeReasonKey: NSUbiquitousKeyValueStoreServerChange,
                    NSUbiquitousKeyValueStoreChangedKeysKey: SyncedSettings.Key.all
                ]
            )
        }

        let book = store.addBook(title: "동기화 검증", author: "검증 작가", category: .literature)
        store.addEntry(
            bookID: book.id, date: Date(), pageFrom: 4, pageTo: 18,
            note: "업그레이드 뒤에도 남는 기록", readingRound: 2, rating: 3.5
        )
        try check(book.readingEntries.count == 1, "optional inverse relationship lost its entry")
        try check(store.entries(for: book.id).first?.ratingValue == 3.5, "entry values changed")
        print("PASS optional relationship preserves inverse and entry values")

        store.toggleFavoriteAuthor("검증 작가")
        try check(
            (cloud.values[SyncedSettings.Key.favoriteAuthors] as? [String]) == ["검증 작가"],
            "favorite author was not written to the cloud store"
        )
        let date = Date(timeIntervalSince1970: 1_792_224_000)
        store.saveCalendarBookOrder([book.id], for: date)
        try check(
            settings.calendarBookOrders.values.contains([book.id]),
            "calendar order was not written through synced settings"
        )
        store.setTrashRetentionDays(14)
        try check(store.trashRetentionDays == 14, "local retention did not publish")
        print("PASS all three local settings use the injected cloud store")

        let anotherBook = store.addBook(title: "다른 책", author: "다른 작가", category: .study)
        cloud.values[SyncedSettings.Key.calendarBookOrders] = try JSONEncoder().encode(
            Dictionary(uniqueKeysWithValues: settings.calendarBookOrders.keys.map {
                ($0, [anotherBook.id, book.id])
            })
        )
        cloud.values[SyncedSettings.Key.favoriteAuthors] = ["다른 기기 작가"]
        cloud.values[SyncedSettings.Key.trashRetentionDays] = 7
        externalChange()
        try check(store.isFavoriteAuthor("다른 기기 작가"), "external authors did not publish")
        try check(!store.isFavoriteAuthor("검증 작가"), "stale favorite remained visible")
        try check(store.trashRetentionDays == 7, "external retention did not publish")
        try check(
            store.orderedBookIDs(for: date, defaultOrder: [book.id, anotherBook.id])
                == [anotherBook.id, book.id],
            "external calendar order did not publish"
        )
        print("PASS external settings notification refreshes the app store")

        let entry = store.entries(for: book.id)[0]
        store.moveEntryToTrash(id: entry.id)
        let referenceDate = Date()
        entry.deletedAt = Calendar.current.date(byAdding: .day, value: -8, to: referenceDate)
        try container.mainContext.save()
        try check(
            store.purgeExpiredEntries(referenceDate: referenceDate) == 1,
            "purge did not use externally changed retention"
        )
        try check(store.entries(for: book.id).isEmpty, "expired entry still exists")
        print("PASS trash expiration uses the synced retention value")

        store.addEntry(
            bookID: book.id, date: Date(), pageFrom: 1, pageTo: 2,
            note: "연결 삭제 검증", readingRound: 1
        )
        store.deleteBook(id: book.id)
        let remaining = try container.mainContext.fetch(FetchDescriptor<ReadingEntry>())
        try check(!remaining.contains { $0.bookID == book.id }, "cascade left orphaned entries")
        print("PASS deleting a book cascades through the optional relationship")

        let incoming = ModelContext(container)
        let importedBook = Book(
            title: "가져온 책", author: "원격 작가", category: .nonfiction
        )
        incoming.insert(importedBook)
        try incoming.save()
        store.refresh()
        try check(store.book(for: importedBook.id) != nil, "refresh missed an imported book")
        print("PASS refresh includes records saved by another context")
        print("PASS all 6 DemoStore integration scenarios")
    }
}
