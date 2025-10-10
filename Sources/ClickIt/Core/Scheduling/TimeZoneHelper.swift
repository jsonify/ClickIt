//
//  TimeZoneHelper.swift
//  ClickIt
//
//  Created by ClickIt on 2025-10-09.
//  Copyright © 2025 ClickIt. All rights reserved.
//

import Foundation

/// Utility class for handling time zone conversions between PST/PDT and GMT/UTC
class TimeZoneHelper {

    // MARK: - Time Zones

    /// Pacific Standard Time (handles PST/PDT automatically)
    static let pacificTimeZone = TimeZone(identifier: "America/Los_Angeles")!

    /// Greenwich Mean Time / UTC
    static let gmtTimeZone = TimeZone(identifier: "GMT")!

    // MARK: - Conversion Methods

    /// Convert a PST/PDT date to GMT
    /// - Parameter pstDate: Date in Pacific time zone
    /// - Returns: Equivalent date in GMT
    static func convertPSTtoGMT(_ pstDate: Date) -> Date {
        // Since Date is always stored as UTC internally, we need to adjust
        // for the difference between how the user sees it vs. how it's stored
        let calendar = Calendar.current
        let pstComponents = calendar.dateComponents(in: pacificTimeZone, from: pstDate)

        var gmtComponents = DateComponents()
        gmtComponents.year = pstComponents.year
        gmtComponents.month = pstComponents.month
        gmtComponents.day = pstComponents.day
        gmtComponents.hour = pstComponents.hour
        gmtComponents.minute = pstComponents.minute
        gmtComponents.second = pstComponents.second
        gmtComponents.timeZone = gmtTimeZone

        let result = calendar.date(from: gmtComponents) ?? pstDate

        #if DEBUG
        print("TimeZoneHelper: PST→GMT conversion")
        print("  Input (PST): \(formatPSTTime(pstDate))")
        print("  Output (GMT): \(formatGMTTime(result))")
        print("  Time difference: \(result.timeIntervalSince(pstDate))s")
        #endif

        return result
    }

    /// Convert a GMT date to PST/PDT
    /// - Parameter gmtDate: Date in GMT time zone
    /// - Returns: Equivalent date in Pacific time zone
    static func convertGMTtoPST(_ gmtDate: Date) -> Date {
        let calendar = Calendar.current
        let gmtComponents = calendar.dateComponents(in: gmtTimeZone, from: gmtDate)

        var pstComponents = DateComponents()
        pstComponents.year = gmtComponents.year
        pstComponents.month = gmtComponents.month
        pstComponents.day = gmtComponents.day
        pstComponents.hour = gmtComponents.hour
        pstComponents.minute = gmtComponents.minute
        pstComponents.second = gmtComponents.second
        pstComponents.timeZone = pacificTimeZone

        return calendar.date(from: pstComponents) ?? gmtDate
    }

    // MARK: - Formatting Methods

    /// Format a date in PST/PDT with clear timezone indicator
    /// - Parameter date: Date to format (stored as GMT internally)
    /// - Returns: Formatted string like "Wed, Oct 9, 2025 at 7:00 AM PDT"
    static func formatPSTTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = pacificTimeZone

        let timeZoneAbbreviation = pacificTimeZone.abbreviation(for: date) ?? "PST"
        return "\(formatter.string(from: date)) \(timeZoneAbbreviation)"
    }

    /// Format a date in GMT with timezone indicator
    /// - Parameter date: Date to format
    /// - Returns: Formatted string like "Wed, Oct 9, 2025 at 3:00 PM GMT"
    static func formatGMTTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = gmtTimeZone

        return "\(formatter.string(from: date)) GMT"
    }

    /// Format both PST and GMT times for comparison
    /// - Parameter gmtDate: Date stored as GMT
    /// - Returns: String like "7:00:00 AM PST → 3:00:00 PM GMT"
    static func formatDualTime(_ gmtDate: Date) -> String {
        let pstFormatter = DateFormatter()
        pstFormatter.dateFormat = "h:mm:ss a"  // Show seconds for precision
        pstFormatter.timeZone = pacificTimeZone

        let gmtFormatter = DateFormatter()
        gmtFormatter.dateFormat = "h:mm:ss a"  // Show seconds for precision
        gmtFormatter.timeZone = gmtTimeZone

        let pstAbbrev = pacificTimeZone.abbreviation(for: gmtDate) ?? "PST"
        let pstTime = pstFormatter.string(from: gmtDate)
        let gmtTime = gmtFormatter.string(from: gmtDate)

        return "\(pstTime) \(pstAbbrev) → \(gmtTime) GMT"
    }

    /// Format time for compact display (just time, no date)
    /// - Parameters:
    ///   - date: Date to format
    ///   - timeZone: Target timezone
    /// - Returns: Compact time string like "7:00 AM"
    static func formatCompactTime(_ date: Date, in timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.timeZone = timeZone
        return formatter.string(from: date)
    }

    // MARK: - Timezone Information

    /// Get current Pacific timezone abbreviation (PST or PDT)
    /// - Returns: Current timezone abbreviation string
    static func currentPacificAbbreviation() -> String {
        return pacificTimeZone.abbreviation(for: Date()) ?? "PST"
    }

    /// Get current offset between Pacific time and GMT
    /// - Returns: String like "GMT-8" or "GMT-7" depending on daylight saving
    static func currentPacificOffset() -> String {
        let offsetSeconds = pacificTimeZone.secondsFromGMT(for: Date())
        let offsetHours = offsetSeconds / 3600

        if offsetHours >= 0 {
            return "GMT+\(offsetHours)"
        } else {
            return "GMT\(offsetHours)"  // Negative sign already included
        }
    }

    /// Check if Pacific timezone is currently in daylight saving time
    /// - Returns: True if currently PDT, false if PST
    static func isCurrentlyDaylightSaving() -> Bool {
        return pacificTimeZone.isDaylightSavingTime(for: Date())
    }

    /// Get a user-friendly description of current timezone status
    /// - Returns: String like "PST (GMT-8)" or "PDT (GMT-7)"
    static func currentTimezoneDescription() -> String {
        let abbrev = currentPacificAbbreviation()
        let offset = currentPacificOffset()
        return "\(abbrev) (\(offset))"
    }

    // MARK: - Validation Helpers

    /// Check if a PST time, when converted to GMT, would be in the future
    /// - Parameter pstDate: Date in Pacific timezone as user sees it
    /// - Returns: True if the resulting GMT time is in the future
    static func isPSTTimeValidForScheduling(_ pstDate: Date) -> Bool {
        let gmtEquivalent = convertPSTtoGMT(pstDate)
        return gmtEquivalent > Date()
    }

    /// Get the next reasonable PST time for scheduling (e.g., next hour at :00)
    /// - Returns: Suggested PST time that would be valid for scheduling
    static func getNextReasonablePSTTime() -> Date {
        var calendar = Calendar.current
        calendar.timeZone = pacificTimeZone

        let now = Date()

        // Get current time in PST
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)

        // Round up to next hour
        components.hour = (components.hour ?? 0) + 1
        components.minute = 0
        components.second = 0

        let result = calendar.date(from: components) ?? now.addingTimeInterval(3600)

        #if DEBUG
        print("TimeZoneHelper: getNextReasonablePSTTime()")
        print("  Current time: \(formatDualTime(now))")
        print("  Next hour PST: \(formatDualTime(result))")
        #endif

        return result
    }
}

// MARK: - Extension for Date Formatting

extension Date {

    /// Get PST representation of this GMT date
    var pstTime: String {
        return TimeZoneHelper.formatPSTTime(self)
    }

    /// Get GMT representation of this date
    var gmtTime: String {
        return TimeZoneHelper.formatGMTTime(self)
    }

    /// Get dual timezone representation
    var dualTime: String {
        return TimeZoneHelper.formatDualTime(self)
    }
}