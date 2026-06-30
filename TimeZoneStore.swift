import Foundation
import Combine

/// Maximum number of time zones the user can track simultaneously.
let kMaxZones = 3

/// Key used for both UserDefaults (standalone) and App Group suite.
private let kStorageKey = "saved_time_zones"

/// App Group ID shared between the main app and the widget extension.
/// Change this to match your provisioning profile's App Group.
let kAppGroupID = "group.com.worldclock.shared"

/// Shared observable store for selected time zones.
/// Persists to App Group UserDefaults so the widget extension can read it.
final class TimeZoneStore: ObservableObject {

    @Published private(set) var zones: [TimeZoneModel] = []

    private let defaults: UserDefaults

    init() {
        // Prefer the App Group suite; fall back to standard defaults in test/preview contexts.
        self.defaults = UserDefaults(suiteName: kAppGroupID) ?? .standard
        load()
        // If nothing was saved, seed with local time zone.
        if zones.isEmpty {
            zones = [TimeZoneModel.local()]
            save()
        }
    }

    // MARK: - Public API

    func add(_ zone: TimeZoneModel) {
        guard zones.count < kMaxZones else { return }
        guard !zones.contains(where: { $0.identifier == zone.identifier }) else { return }
        zones.append(zone)
        save()
    }

    func remove(at offsets: IndexSet) {
        // Never allow removing index 0 (local zone).
        let safeOffsets = offsets.filter { $0 != 0 }
        zones.remove(atOffsets: IndexSet(safeOffsets))
        save()
    }

    func remove(_ zone: TimeZoneModel) {
        guard let idx = zones.firstIndex(of: zone), idx != 0 else { return }
        zones.remove(at: idx)
        save()
    }

    func move(from source: IndexSet, to destination: Int) {
        // Do not allow moving the local zone away from index 0.
        if source.contains(0) { return }
        let safeDestination = max(destination, 1)
        zones.move(fromOffsets: source, toOffset: safeDestination)
        save()
    }

    func canAdd(_ zone: TimeZoneModel) -> Bool {
        zones.count < kMaxZones && !zones.contains(where: { $0.identifier == zone.identifier })
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(zones) {
            defaults.set(data, forKey: kStorageKey)
        }
    }

    private func load() {
        guard let data = defaults.data(forKey: kStorageKey),
              let decoded = try? JSONDecoder().decode([TimeZoneModel].self, from: data)
        else { return }
        zones = decoded
    }
}
