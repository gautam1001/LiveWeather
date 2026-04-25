import Domain
import Foundation

public struct WeatherCachePolicy: Sendable {
    public let currentWeatherTTL: TimeInterval
    public let forecastTTL: TimeInterval

    public init(currentWeatherTTL: TimeInterval, forecastTTL: TimeInterval) {
        self.currentWeatherTTL = currentWeatherTTL
        self.forecastTTL = forecastTTL
    }

    public static let live = WeatherCachePolicy(
        currentWeatherTTL: 5 * 60,
        forecastTTL: 15 * 60
    )
}

public actor CachedWeatherRemoteDataSource: WeatherRemoteDataSource {
    private let remoteDataSource: any WeatherRemoteDataSource
    private let cachePolicy: WeatherCachePolicy
    private let dateProvider: @Sendable () -> Date

    private var currentWeatherCache: [CurrentWeatherCacheKey: CacheEntry<CurrentWeatherResponseDTO>] = [:]
    private var forecastCache: [ForecastCacheKey: CacheEntry<ForecastResponseDTO>] = [:]
    private var inFlightCurrentWeatherRequests: [CurrentWeatherCacheKey: Task<CurrentWeatherResponseDTO, Error>] = [:]
    private var inFlightForecastRequests: [ForecastCacheKey: Task<ForecastResponseDTO, Error>] = [:]

    public init(
        remoteDataSource: any WeatherRemoteDataSource,
        cachePolicy: WeatherCachePolicy = .live,
        dateProvider: @escaping @Sendable () -> Date = Date.init
    ) {
        self.remoteDataSource = remoteDataSource
        self.cachePolicy = cachePolicy
        self.dateProvider = dateProvider
    }

    public func fetchWeather(for location: Location) async throws -> CurrentWeatherResponseDTO {
        let key = CurrentWeatherCacheKey(queryValue: makeCurrentWeatherQueryValue(for: location))

        if let cachedResponse = cachedCurrentWeather(for: key) {
            return cachedResponse
        }

        if let inFlightRequest = inFlightCurrentWeatherRequests[key] {
            return try await inFlightRequest.value
        }

        let request = Task {
            try await remoteDataSource.fetchWeather(for: location)
        }
        inFlightCurrentWeatherRequests[key] = request

        do {
            let response = try await request.value
            currentWeatherCache[key] = CacheEntry(
                value: response,
                expirationDate: makeExpirationDate(ttl: cachePolicy.currentWeatherTTL)
            )
            inFlightCurrentWeatherRequests[key] = nil
            return response
        } catch {
            inFlightCurrentWeatherRequests[key] = nil
            throw error
        }
    }

    public func fetchForecast(for location: String, days: Int) async throws -> ForecastResponseDTO {
        let key = ForecastCacheKey(locationQuery: normalize(locationQuery: location), days: days)

        if let cachedResponse = cachedForecast(for: key) {
            return cachedResponse
        }

        if let inFlightRequest = inFlightForecastRequests[key] {
            return try await inFlightRequest.value
        }

        let request = Task {
            try await remoteDataSource.fetchForecast(for: location, days: days)
        }
        inFlightForecastRequests[key] = request

        do {
            let response = try await request.value
            forecastCache[key] = CacheEntry(
                value: response,
                expirationDate: makeExpirationDate(ttl: cachePolicy.forecastTTL)
            )
            inFlightForecastRequests[key] = nil
            return response
        } catch {
            inFlightForecastRequests[key] = nil
            throw error
        }
    }

    private func cachedCurrentWeather(for key: CurrentWeatherCacheKey) -> CurrentWeatherResponseDTO? {
        guard let entry = currentWeatherCache[key] else {
            return nil
        }

        guard entry.expirationDate > dateProvider() else {
            currentWeatherCache[key] = nil
            return nil
        }

        return entry.value
    }

    private func cachedForecast(for key: ForecastCacheKey) -> ForecastResponseDTO? {
        guard let entry = forecastCache[key] else {
            return nil
        }

        guard entry.expirationDate > dateProvider() else {
            forecastCache[key] = nil
            return nil
        }

        return entry.value
    }

    private func makeExpirationDate(ttl: TimeInterval) -> Date {
        dateProvider().addingTimeInterval(ttl)
    }

    private func makeCurrentWeatherQueryValue(for location: Location) -> String {
        let trimmedName = location.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            return "\(location.coordinate.latitude),\(location.coordinate.longitude)"
        }

        return trimmedName.lowercased()
    }

    private func normalize(locationQuery: String) -> String {
        locationQuery
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}

private struct CacheEntry<Value: Sendable> {
    let value: Value
    let expirationDate: Date
}

private struct CurrentWeatherCacheKey: Hashable {
    let queryValue: String
}

private struct ForecastCacheKey: Hashable {
    let locationQuery: String
    let days: Int
}
