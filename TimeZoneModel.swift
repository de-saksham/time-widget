import Foundation

/// Represents a single time zone entry displayed in the widget/app.
struct TimeZoneModel: Identifiable, Codable, Equatable, Hashable {
    var id: String { identifier }
    let identifier: String   // e.g. "America/New_York"
    var customLabel: String? // optional user-supplied name

    /// The underlying TimeZone value.
    var timeZone: TimeZone {
        TimeZone(identifier: identifier) ?? .current
    }

    /// Display name: custom label → city extracted from identifier → abbreviation.
    var displayName: String {
        if let label = customLabel, !label.isEmpty { return label }
        // Extract city from "Region/City" identifier.
        if let city = identifier.split(separator: "/").last {
            return city.replacingOccurrences(of: "_", with: " ")
        }
        return timeZone.abbreviation() ?? identifier
    }

    /// UTC offset string, e.g. "UTC+5:30", respecting DST.
    func utcOffset(for date: Date = Date()) -> String {
        let seconds = timeZone.secondsFromGMT(for: date)
        let hours   = abs(seconds) / 3600
        let minutes = (abs(seconds) % 3600) / 60
        let sign    = seconds >= 0 ? "+" : "-"
        if minutes == 0 {
            return "UTC\(sign)\(hours)"
        }
        return String(format: "UTC%@%d:%02d", sign, hours, minutes)
    }

    /// Formatted current time string (12h or 24h based on system preference).
    func formattedTime(for date: Date = Date()) -> String {
        let fmt = DateFormatter()
        fmt.timeZone = timeZone
        fmt.timeStyle = .short
        fmt.dateStyle = .none
        return fmt.string(from: date)
    }

    /// Short date string, e.g. "Mon, Jun 30".
    func formattedDate(for date: Date = Date()) -> String {
        let fmt = DateFormatter()
        fmt.timeZone = timeZone
        fmt.dateFormat = "EEE, MMM d"
        return fmt.string(from: date)
    }

    /// Hour (0–23) in this zone for the given date.
    func hour(for date: Date = Date()) -> Int {
        var cal = Calendar.current
        cal.timeZone = timeZone
        return cal.component(.hour, from: date)
    }

    /// Whether the given date falls roughly in nighttime (20:00–06:00) in this zone.
    func isNight(for date: Date = Date()) -> Bool {
        let h = hour(for: date)
        return h >= 20 || h < 6
    }

    // MARK: - Static helpers

    static func local() -> TimeZoneModel {
        TimeZoneModel(identifier: TimeZone.current.identifier, customLabel: "Local")
    }

    /// All TimeZone identifiers sorted alphabetically, grouped by region prefix.
    static var allSorted: [TimeZoneModel] {
        TimeZone.knownTimeZoneIdentifiers
            .sorted()
            .map { TimeZoneModel(identifier: $0) }
    }
}
