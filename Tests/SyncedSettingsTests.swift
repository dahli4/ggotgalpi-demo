import Foundation

private final class FakeCloud: NSObject, SyncedSettingsCloudStore {
    var values: [String: Any] = [:]
    var writes: [String] = []
    var synchronizeCount = 0
    var synchronizeResult = true

    func object(forKey key: String) -> Any? { values[key] }
    func set(_ value: Any?, forKey key: String) {
        values[key] = value
        writes.append(key)
    }
    func synchronize() -> Bool {
        synchronizeCount += 1
        return synchronizeResult
    }
}

@MainActor
private final class Fixture {
    let suite = "SyncedSettingsTests.\(UUID().uuidString)"
    let defaults: UserDefaults
    let cloud = FakeCloud()
    let center = NotificationCenter()

    init() {
        defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
    }

    func makeSettings() -> SyncedSettings {
        SyncedSettings(cloud: cloud, defaults: defaults, notificationCenter: center)
    }

    func post(
        reason: Int? = NSUbiquitousKeyValueStoreServerChange,
        keys: [String]? = nil,
        object: AnyObject? = nil
    ) {
        var info: [String: Any] = [:]
        info[NSUbiquitousKeyValueStoreChangeReasonKey] = reason
        info[NSUbiquitousKeyValueStoreChangedKeysKey] = keys
        center.post(
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: object ?? cloud,
            userInfo: info
        )
    }
}

private struct CheckFailure: Error, CustomStringConvertible {
    let description: String
}

private func check(
    _ condition: @autoclosure () -> Bool,
    _ message: String,
    line: UInt = #line
) throws {
    if !condition() { throw CheckFailure(description: "Line \(line): \(message)") }
}

@main
@MainActor
struct SyncedSettingsTests {
    private typealias Key = SyncedSettings.Key
    private static let id = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    private static var passed = 0

    private static func test(_ name: String, _ body: (Fixture) throws -> Void) throws {
        let fixture = Fixture()
        defer { fixture.defaults.removePersistentDomain(forName: fixture.suite) }
        try body(fixture)
        passed += 1
        print("PASS \(name)")
    }

    static func main() throws {
        let localOrders = try JSONEncoder().encode(["2026-10-17": [id]])
        let remoteOrders = try JSONEncoder().encode(["2026-10-18": [id]])

        try test("existing cloud wins without overwriting legacy or uploading") { f in
            f.defaults.set(["legacy"], forKey: Key.favoriteAuthors)
            f.defaults.set(localOrders, forKey: Key.calendarBookOrders)
            f.defaults.set(7, forKey: Key.trashRetentionDays)
            f.cloud.values = [
                Key.favoriteAuthors: ["remote"],
                Key.calendarBookOrders: remoteOrders,
                Key.trashRetentionDays: 14
            ]
            let settings = f.makeSettings()
            try check(settings.favoriteAuthors == ["remote"], "cloud authors must win")
            try check(settings.calendarBookOrders == ["2026-10-18": [id]], "cloud orders must win")
            try check(settings.trashRetentionDays == 14, "cloud retention must win")
            try check(f.defaults.stringArray(forKey: Key.favoriteAuthors) == ["legacy"], "retain legacy authors")
            try check(f.defaults.data(forKey: Key.calendarBookOrders) == localOrders, "retain legacy orders")
            try check(f.defaults.integer(forKey: Key.trashRetentionDays) == 7, "retain legacy retention")
            try check(f.cloud.writes.isEmpty, "initialization must not write cloud")
            try check(f.cloud.synchronizeCount == 1, "synchronize once on launch")
        }

        try test("absent cloud preserves legacy with every supported retention") { f in
            f.defaults.set(["legacy"], forKey: Key.favoriteAuthors)
            f.defaults.set(localOrders, forKey: Key.calendarBookOrders)
            f.cloud.synchronizeResult = false
            for days in [7, 14, 30] {
                f.defaults.set(days, forKey: Key.trashRetentionDays)
                let settings = f.makeSettings()
                try check(settings.favoriteAuthors == ["legacy"], "fallback authors")
                try check(settings.calendarBookOrdersData == localOrders, "fallback data")
                try check(settings.trashRetentionDays == days, "fallback retention \(days)")
            }
            try check(f.cloud.writes.isEmpty, "failed synchronize must not trigger migration")
        }

        try test("absent stores use empty collections and thirty days") { f in
            let settings = f.makeSettings()
            try check(settings.favoriteAuthors.isEmpty, "default authors")
            try check(settings.calendarBookOrders.isEmpty, "default orders")
            try check(settings.trashRetentionDays == 30, "default retention")
            try check(f.cloud.writes.isEmpty, "defaults are not cloud writes")
        }

        try test("authoritative remote empty arrays and data clear legacy") { f in
            f.defaults.set(["legacy"], forKey: Key.favoriteAuthors)
            f.defaults.set(localOrders, forKey: Key.calendarBookOrders)
            f.cloud.values[Key.favoriteAuthors] = [String]()
            f.cloud.values[Key.calendarBookOrders] = Data()
            let settings = f.makeSettings()
            try check(settings.favoriteAuthors.isEmpty, "empty array is present")
            try check(settings.calendarBookOrdersData.isEmpty, "empty bytes are present")
            try check(settings.calendarBookOrders.isEmpty, "empty bytes decode as clear")
            let emptyJSON = Data("{}".utf8)
            f.cloud.values[Key.calendarBookOrders] = emptyJSON
            f.post(keys: [Key.calendarBookOrders])
            try check(settings.calendarBookOrdersData == emptyJSON, "empty JSON is authoritative too")
            try check(settings.calendarBookOrders.isEmpty, "empty dictionary clears orders")
        }

        try test("local writes update defaults cloud cache and callback") { f in
            let settings = f.makeSettings()
            var notifications = 0
            settings.onChange = {
                notifications += 1
                precondition(Thread.isMainThread)
            }
            settings.setFavoriteAuthors(["edited"])
            try check(settings.favoriteAuthors == ["edited"], "local author cache")
            try check(f.cloud.values[Key.favoriteAuthors] as? [String] == ["edited"], "cloud author write")
            try check(f.defaults.stringArray(forKey: Key.favoriteAuthors) == ["edited"], "defaults author write")
            try check(settings.setCalendarBookOrdersData(localOrders), "accept valid JSON")
            try check(settings.calendarBookOrdersData == localOrders, "local order cache")
            try check(f.cloud.values[Key.calendarBookOrders] as? Data == localOrders, "cloud order write")
            try check(f.defaults.data(forKey: Key.calendarBookOrders) == localOrders, "defaults order write")
            for days in [7, 14, 30] {
                try check(settings.setTrashRetentionDays(days), "accept \(days)")
                try check(settings.trashRetentionDays == days, "retention cache")
                try check(f.cloud.values[Key.trashRetentionDays] as? Int == days, "cloud retention write")
                try check(f.defaults.integer(forKey: Key.trashRetentionDays) == days, "defaults retention write")
            }
            try check(notifications == 5, "one callback for each changed write")
            settings.setFavoriteAuthors(["edited"])
            try check(notifications == 5, "unchanged write should not republish")
            try check(f.cloud.writes.count == 6, "explicit same-value write still uploads fallback")
            settings.setFavoriteAuthors([])
            try check(settings.setCalendarBookOrdersData(Data()), "local empty data accepted")
            try check(f.cloud.values[Key.favoriteAuthors] as? [String] == [], "write authoritative empty array")
            try check(f.cloud.values[Key.calendarBookOrders] as? Data == Data(), "write authoritative empty data")
            try check(f.cloud.synchronizeCount == 1, "do not synchronize on each edit")
        }

        try test("external changed keys publish complete cache without echo writes") { f in
            let settings = f.makeSettings()
            var snapshots: [[String]] = []
            settings.onChange = { snapshots.append(settings.favoriteAuthors) }
            defer { settings.onChange = nil }
            f.cloud.values = [
                Key.favoriteAuthors: ["external"],
                Key.calendarBookOrders: remoteOrders,
                Key.trashRetentionDays: 7
            ]
            f.post(keys: [Key.favoriteAuthors])
            try check(snapshots == [["external"]], "synchronous callback sees updated cache")
            try check(settings.trashRetentionDays == 30, "unlisted key not read")
            try check(settings.calendarBookOrders.isEmpty, "unlisted order not read")
            f.post(keys: ["unrelated"])
            try check(snapshots.count == 1, "unrelated keys do not publish")
            f.post(reason: NSUbiquitousKeyValueStoreInitialSyncChange)
            try check(settings.trashRetentionDays == 7, "missing keys reload all")
            try check(settings.calendarBookOrdersData == remoteOrders, "initial sync loads orders")
            try check(snapshots.count == 2, "batch produces one callback")
            f.post(keys: Key.all)
            try check(snapshots.count == 2, "unchanged external values do not publish")
            try check(f.cloud.writes.isEmpty, "external changes must not echo")
            try check(f.defaults.object(forKey: Key.favoriteAuthors) == nil, "remote data not saved as local")
        }

        try test("late cloud arrival supersedes fallback and removal restores local") { f in
            f.defaults.set(["legacy"], forKey: Key.favoriteAuthors)
            let settings = f.makeSettings()
            f.cloud.values[Key.favoriteAuthors] = ["late remote"]
            f.post(reason: NSUbiquitousKeyValueStoreInitialSyncChange, keys: [Key.favoriteAuthors])
            try check(settings.favoriteAuthors == ["late remote"], "late cloud wins")
            f.cloud.values.removeValue(forKey: Key.favoriteAuthors)
            f.post(keys: [Key.favoriteAuthors])
            try check(settings.favoriteAuthors == ["legacy"], "absent differs from empty")
            try check(f.cloud.writes.isEmpty, "fallback does not upload")
        }

        try test("account change discards every old cloud cache without uploading") { f in
            f.cloud.values = [
                Key.favoriteAuthors: ["old account"],
                Key.calendarBookOrders: remoteOrders,
                Key.trashRetentionDays: 7
            ]
            let settings = f.makeSettings()
            var callbacks = 0
            settings.onChange = { callbacks += 1 }
            f.cloud.values = [:]
            f.post(reason: NSUbiquitousKeyValueStoreAccountChange, keys: [])
            try check(settings.favoriteAuthors.isEmpty, "clear old authors")
            try check(settings.calendarBookOrders.isEmpty, "clear old orders")
            try check(settings.trashRetentionDays == 30, "clear old retention")
            try check(callbacks == 1, "publish cleared cache")
            f.cloud.values = [Key.favoriteAuthors: ["new account"], Key.trashRetentionDays: 14]
            f.post(reason: NSUbiquitousKeyValueStoreAccountChange, keys: [Key.favoriteAuthors])
            try check(settings.favoriteAuthors == ["new account"], "read new account")
            try check(settings.trashRetentionDays == 14, "account reload ignores partial key list")
            try check(f.cloud.writes.isEmpty, "never transfer previous account data")
        }

        try test("account change preserves local fallback without migrating it") { f in
            f.defaults.set(["device local"], forKey: Key.favoriteAuthors)
            f.defaults.set(localOrders, forKey: Key.calendarBookOrders)
            f.defaults.set(14, forKey: Key.trashRetentionDays)
            f.cloud.values = [Key.favoriteAuthors: ["old cloud"], Key.trashRetentionDays: 7]
            let settings = f.makeSettings()
            f.cloud.values = [:]
            f.post(reason: NSUbiquitousKeyValueStoreAccountChange)
            try check(settings.favoriteAuthors == ["device local"], "preserve local fallback")
            try check(settings.calendarBookOrdersData == localOrders, "preserve local order")
            try check(settings.trashRetentionDays == 14, "preserve local retention")
            try check(f.cloud.writes.isEmpty, "do not upload fallback to new account")
        }

        try test("malformed remote values fall back and invalid local writes are rejected") { f in
            f.defaults.set(["legacy"], forKey: Key.favoriteAuthors)
            f.defaults.set(localOrders, forKey: Key.calendarBookOrders)
            f.defaults.set(14, forKey: Key.trashRetentionDays)
            let settings = f.makeSettings()
            let malformedData = [
                Data("not JSON".utf8), Data("[]".utf8),
                Data("{\"2026-10-17\":[\"not-a-uuid\"]}".utf8),
                Data("{\"2026-10-17\":null}".utf8)
            ]
            for data in malformedData {
                f.cloud.values = [
                    Key.favoriteAuthors: [1, 2],
                    Key.calendarBookOrders: data,
                    Key.trashRetentionDays: 8
                ]
                f.post(keys: Key.all)
                try check(settings.favoriteAuthors == ["legacy"], "malformed authors fallback")
                try check(settings.calendarBookOrdersData == localOrders, "malformed JSON fallback")
                try check(settings.trashRetentionDays == 14, "invalid retention fallback")
                try check(!settings.setCalendarBookOrdersData(data), "reject malformed local data")
            }
            for bad: Any in ["7", true, 7.5, -7, 0, 31] {
                f.cloud.values[Key.trashRetentionDays] = bad
                f.post(keys: [Key.trashRetentionDays])
                try check(settings.trashRetentionDays == 14, "reject invalid remote integer")
            }
            try check(!settings.setTrashRetentionDays(9), "reject unsupported local retention")
            try check(f.cloud.writes.isEmpty, "invalid writes have no effects")
            try check(f.defaults.data(forKey: Key.calendarBookOrders) == localOrders, "keep valid legacy data")
            try check(f.defaults.integer(forKey: Key.trashRetentionDays) == 14, "keep valid legacy retention")
        }

        try test("malformed legacy and wrong remote types use safe defaults") { f in
            for storeKey in Key.all {
                f.defaults.set("invalid", forKey: storeKey)
                f.cloud.values[storeKey] = NSNull()
            }
            let settings = f.makeSettings()
            try check(settings.favoriteAuthors.isEmpty, "invalid legacy authors")
            try check(settings.calendarBookOrders.isEmpty, "invalid legacy data")
            try check(settings.trashRetentionDays == 30, "invalid legacy retention")
        }

        try test("notification filtering ignores foreign stores quota and unknown reasons") { f in
            let settings = f.makeSettings()
            var callbacks = 0
            settings.onChange = { callbacks += 1 }
            f.cloud.values[Key.favoriteAuthors] = ["remote"]
            f.post(keys: Key.all, object: FakeCloud())
            f.post(reason: NSUbiquitousKeyValueStoreQuotaViolationChange)
            f.post(reason: 999)
            try check(callbacks == 0, "ignore non-value events")
            try check(settings.favoriteAuthors.isEmpty, "cache unchanged")
            f.post(reason: nil)
            try check(settings.favoriteAuthors == ["remote"], "missing reason reloads")
            try check(callbacks == 1, "missing reason publishes valid values")
        }

        try test("observer does not retain helper after release") { f in
            var settings: SyncedSettings? = f.makeSettings()
            weak let released = settings
            settings = nil
            try check(released == nil, "observer must not leak helper")
            f.post()
        }
        print("PASS all \(passed) deterministic settings tests")
    }
}
