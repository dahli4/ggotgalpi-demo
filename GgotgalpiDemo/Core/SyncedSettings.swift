import Foundation

protocol SyncedSettingsCloudStore: AnyObject {
    func object(forKey key: String) -> Any?
    func set(_ value: Any?, forKey key: String)
    @discardableResult func synchronize() -> Bool
}

extension NSUbiquitousKeyValueStore: SyncedSettingsCloudStore {}

/// Main-actor settings with whole-value, per-key last-writer-wins cloud storage.
/// Defaults hold device-local choices, never a mirror of another account's cloud data.
/// Missing cloud values use defaults but do not automatically upload them: synchronize()
/// is not an initial-download barrier. Only explicit setters write to the cloud.
@MainActor
final class SyncedSettings: NSObject {
    enum Key {
        static let favoriteAuthors = "ggotgalpi.favorite-authors.v1"
        static let calendarBookOrders = "ggotgalpi.calendar-book-orders.v1"
        static let trashRetentionDays = "ggotgalpi.settings.trash-retention-days"
        static let all = [favoriteAuthors, calendarBookOrders, trashRetentionDays]
    }

    private(set) var favoriteAuthors: [String] = []
    private(set) var calendarBookOrdersData = Data()
    private(set) var trashRetentionDays = 30

    /// Runs on the main actor after a local or external change updates the cache.
    /// Install after initialization, then copy the initial values into the UI yourself.
    var onChange: (() -> Void)?

    var calendarBookOrders: [String: [UUID]] {
        (try? JSONDecoder().decode([String: [UUID]].self, from: calendarBookOrdersData)) ?? [:]
    }

    private let cloud: any SyncedSettingsCloudStore
    private let defaults: UserDefaults
    private let notificationCenter: NotificationCenter

    init(
        cloud: any SyncedSettingsCloudStore = NSUbiquitousKeyValueStore.default,
        defaults: UserDefaults = .standard,
        notificationCenter: NotificationCenter = .default
    ) {
        self.cloud = cloud
        self.defaults = defaults
        self.notificationCenter = notificationCenter
        super.init()
        notificationCenter.addObserver(
            self,
            selector: #selector(cloudChanged(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloud
        )
        cloud.synchronize()
        reload(keys: Key.all)
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    func setFavoriteAuthors(_ authors: [String]) {
        defaults.set(authors, forKey: Key.favoriteAuthors)
        cloud.set(authors, forKey: Key.favoriteAuthors)
        let changed = favoriteAuthors != authors
        favoriteAuthors = authors
        if changed { onChange?() }
    }

    /// Accepts the existing JSON dictionary encoding, or zero bytes as an explicit clear.
    /// Rejects malformed data without changing either store.
    @discardableResult
    func setCalendarBookOrdersData(_ data: Data) -> Bool {
        guard Self.validCalendarData(data) != nil else { return false }
        defaults.set(data, forKey: Key.calendarBookOrders)
        cloud.set(data, forKey: Key.calendarBookOrders)
        let changed = calendarBookOrdersData != data
        calendarBookOrdersData = data
        if changed { onChange?() }
        return true
    }

    @discardableResult
    func setTrashRetentionDays(_ days: Int) -> Bool {
        guard [7, 14, 30].contains(days) else { return false }
        defaults.set(days, forKey: Key.trashRetentionDays)
        cloud.set(days, forKey: Key.trashRetentionDays)
        let changed = trashRetentionDays != days
        trashRetentionDays = days
        if changed { onChange?() }
        return true
    }

    @objc nonisolated private func cloudChanged(_ notification: Notification) {
        let reason = notification.userInfo?[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int
        let keys = notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String]
        // Keep main-thread notifications synchronous; marshal other senders to the UI actor.
        if Thread.isMainThread {
            MainActor.assumeIsolated { handleCloudChange(reason: reason, keys: keys) }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.handleCloudChange(reason: reason, keys: keys)
            }
        }
    }

    private func handleCloudChange(reason: Int?, keys: [String]?) {
        switch reason {
        case NSUbiquitousKeyValueStoreAccountChange:
            // Apple replaces the store's contents for the new account. Discard all cached
            // remote values, even when the supplied changed-key list is empty or partial.
            reload(keys: Key.all)
        case NSUbiquitousKeyValueStoreServerChange, NSUbiquitousKeyValueStoreInitialSyncChange, nil:
            reload(keys: keys ?? Key.all)
        default:
            // Quota violations and unknown reasons are not incoming settings values.
            break
        }
    }

    private func reload(keys: [String]) {
        let oldAuthors = favoriteAuthors
        let oldOrders = calendarBookOrdersData
        let oldRetention = trashRetentionDays
        for key in keys {
            let remote = cloud.object(forKey: key)
            let local = defaults.object(forKey: key)
            switch key {
            case Key.favoriteAuthors:
                favoriteAuthors = (remote as? [String]) ?? (local as? [String]) ?? []
            case Key.calendarBookOrders:
                calendarBookOrdersData = Self.validCalendarData(remote)
                    ?? Self.validCalendarData(local) ?? Data()
            case Key.trashRetentionDays:
                trashRetentionDays = Self.validRetention(remote) ?? Self.validRetention(local) ?? 30
            default:
                break
            }
        }
        if oldAuthors != favoriteAuthors || oldOrders != calendarBookOrdersData
            || oldRetention != trashRetentionDays {
            onChange?()
        }
    }

    private static func validCalendarData(_ value: Any?) -> Data? {
        guard let data = value as? Data else { return nil }
        guard data.isEmpty || (try? JSONDecoder().decode([String: [UUID]].self, from: data)) != nil
        else { return nil }
        return data
    }

    private static func validRetention(_ value: Any?) -> Int? {
        guard let days = value as? Int, [7, 14, 30].contains(days) else { return nil }
        return days
    }
}
