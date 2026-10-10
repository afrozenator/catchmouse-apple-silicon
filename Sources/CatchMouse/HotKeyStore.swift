import Foundation

/// Persists user-chosen shortcuts in `UserDefaults`.
///
/// Per-display bindings are keyed by a stable display UUID (see
/// `DisplayManager.stableKey`) so they survive reconnects and reordering.
/// A missing binding means "use the positional default" (see `Shortcuts`).
final class HotKeyStore {
    static let shared = HotKeyStore()

    private let defaults: UserDefaults
    private let perDisplayKey = "perDisplayBindings.v1"
    private let nextKey = "nextBinding.v1"
    private let prevKey = "prevBinding.v1"
    private let disabledDisplaysKey = "disabledDisplayBindings.v1"
    private let disabledNextKey = "disabledNextBinding.v1"
    private let disabledPrevKey = "disabledPrevBinding.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Per-display bindings

    private func perDisplayMap() -> [String: KeyCombo] {
        guard let data = defaults.data(forKey: perDisplayKey),
              let map = try? JSONDecoder().decode([String: KeyCombo].self, from: data) else { return [:] }
        return map.filter { $0.value.isValid }
    }

    func binding(forDisplay key: String) -> KeyCombo? { perDisplayMap()[key] }

    func isDisplayDisabled(_ key: String) -> Bool {
        (defaults.stringArray(forKey: disabledDisplaysKey) ?? []).contains(key)
    }

    func setBinding(_ combo: KeyCombo?, forDisplay key: String) {
        var map = perDisplayMap()
        map[key] = combo
        if let data = try? JSONEncoder().encode(map) { defaults.set(data, forKey: perDisplayKey) }
        var disabled = Set(defaults.stringArray(forKey: disabledDisplaysKey) ?? [])
        if combo == nil { disabled.insert(key) } else { disabled.remove(key) }
        defaults.set(disabled.sorted(), forKey: disabledDisplaysKey)
    }

    // MARK: - Cycle bindings

    private func combo(forKey key: String) -> KeyCombo? {
        guard let data = defaults.data(forKey: key) else { return nil }
        guard let combo = try? JSONDecoder().decode(KeyCombo.self, from: data), combo.isValid else { return nil }
        return combo
    }

    private func setCombo(_ combo: KeyCombo?, forKey key: String) {
        if let combo, let data = try? JSONEncoder().encode(combo) { defaults.set(data, forKey: key) }
        else { defaults.removeObject(forKey: key) }
    }

    func nextBinding() -> KeyCombo? { combo(forKey: nextKey) }
    func prevBinding() -> KeyCombo? { combo(forKey: prevKey) }
    var isNextDisabled: Bool { defaults.bool(forKey: disabledNextKey) }
    var isPrevDisabled: Bool { defaults.bool(forKey: disabledPrevKey) }
    func setNext(_ combo: KeyCombo?) {
        setCombo(combo, forKey: nextKey)
        defaults.set(combo == nil, forKey: disabledNextKey)
    }
    func setPrev(_ combo: KeyCombo?) {
        setCombo(combo, forKey: prevKey)
        defaults.set(combo == nil, forKey: disabledPrevKey)
    }

    // MARK: - Reset

    func resetAll() {
        defaults.removeObject(forKey: perDisplayKey)
        defaults.removeObject(forKey: nextKey)
        defaults.removeObject(forKey: prevKey)
        defaults.removeObject(forKey: disabledDisplaysKey)
        defaults.removeObject(forKey: disabledNextKey)
        defaults.removeObject(forKey: disabledPrevKey)
    }
}
