import Foundation

/// Centralised formatting helpers that respect system 12/24h preference.
enum TimeFormatter {

    static func time(_ date: Date, in timeZone: TimeZone) -> String {
        let fmt = DateFormatter()
        fmt.timeZone = timeZone
        fmt.timeStyle = .short
        fmt.dateStyle = .none
        return fmt.string(from: date)
    }

    static func shortDate(_ date: Date, in timeZone: TimeZone) -> String {
        let fmt = DateFormatter()
        fmt.timeZone = timeZone
        fmt.dateFormat = "EEE, MMM d"
        return fmt.string(from: date)
    }

    /// Returns the hour label for a given 0–23 hour, respecting locale 12/24h.
    static func hourLabel(_ hour: Int) -> String {
        // Use a fixed reference date (midnight UTC) + offset.
        var comps = DateComponents()
        comps.year = 2000; comps.month = 1; comps.day = 1
        comps.hour = hour; comps.minute = 0; comps.second = 0
        comps.timeZone = TimeZone(secondsFromGMT: 0)
        guard let date = Calendar(identifier: .gregorian).date(from: comps) else {
            return "\(hour)"
        }
        let fmt = DateFormatter()
        fmt.timeZone = TimeZone(secondsFromGMT: 0)!
        // Mirror the user's locale format but strip minutes.
        let uses24h = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: .current)?.contains("H") ?? false
        fmt.dateFormat = uses24h ? "H" : "ha"
        return fmt.string(from: date)
    }
}
