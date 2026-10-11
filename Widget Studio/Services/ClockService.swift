import SwiftUI
import Combine

/// Model representing a monitored world city timezone
public struct WorldCityTime: Identifiable, Hashable {
    public let id: String
    public let cityName: String
    public let timeZoneIdentifier: String
    public let countryCode: String

    public init(id: String, cityName: String, timeZoneIdentifier: String, countryCode: String) {
        self.id = id
        self.cityName = cityName
        self.timeZoneIdentifier = timeZoneIdentifier
        self.countryCode = countryCode
    }

    public var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .current
    }

    public var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: Date())
    }

    public var timeOffsetDescription: String {
        let currentSeconds = TimeZone.current.secondsFromGMT()
        let targetSeconds = timeZone.secondsFromGMT()
        let diffHours = (targetSeconds - currentSeconds) / 3600

        if diffHours == 0 {
            return "Same time"
        } else if diffHours > 0 {
            return "+\(diffHours)HRS"
        } else {
            return "\(diffHours)HRS"
        }
    }
}

/// Service managing World Clock data and time offsets for Liquid Glass widgets.
@MainActor
public final class ClockService: ObservableObject {
    public static let shared = ClockService()

    @Published public var cities: [WorldCityTime] = [
        WorldCityTime(id: "tyo", cityName: "Tokyo", timeZoneIdentifier: "Asia/Tokyo", countryCode: "JP"),
        WorldCityTime(id: "lon", cityName: "London", timeZoneIdentifier: "Europe/London", countryCode: "GB"),
        WorldCityTime(id: "nyc", cityName: "New York", timeZoneIdentifier: "America/New_York", countryCode: "US"),
        WorldCityTime(id: "sfo", cityName: "San Francisco", timeZoneIdentifier: "America/Los_Angeles", countryCode: "US"),
        WorldCityTime(id: "par", cityName: "Paris", timeZoneIdentifier: "Europe/Paris", countryCode: "FR")
    ]

    public init() {}
}
