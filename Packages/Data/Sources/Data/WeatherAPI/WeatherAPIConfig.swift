import Foundation

public struct WeatherAPIConfig: Sendable {
    public let baseURL: URL
    public let apiKey: String
    public let days: Int
    public let includeAlerts: Bool
    public let includeAQI: Bool
    public let language: String?

    public init(
        baseURL: URL,
        apiKey: String,
        days: Int = 7,
        includeAlerts: Bool = true,
        includeAQI: Bool = false,
        language: String? = nil
    ) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.days = days
        self.includeAlerts = includeAlerts
        self.includeAQI = includeAQI
        self.language = language
    }

    public static func weatherAPIDefault(apiKey: String) -> WeatherAPIConfig {
        WeatherAPIConfig(
            baseURL: URL(string: "https://api.weatherapi.com/v1/forecast.json")!,
            apiKey: apiKey,
            days: 7,
            includeAlerts: true,
            includeAQI: false,
            language: nil
        )
    }
}

