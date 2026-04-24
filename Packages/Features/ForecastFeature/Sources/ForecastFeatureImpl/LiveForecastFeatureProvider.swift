import Data
import ForecastFeatureAPI
import Foundation

public actor LiveForecastFeatureProvider {
    private let service: LiveForecastFeatureService

    public init(weatherAPIKey: String, weatherAPIURL: String) {
        service = Self.liveService(weatherAPIKey: weatherAPIKey, weatherAPIURL: weatherAPIURL)
    }

    public init(service: LiveForecastFeatureService) {
        self.service = service
    }

    public func fetchForecast(location: String, days: Int) async throws -> [ForecastDay] {
        let safeLocation = String(location)
        return try await service.fetchForecast(location: safeLocation, days: days)
    }
}

extension LiveForecastFeatureProvider: ForecastFeatureProviding {}

public enum ForecastFeatureFactory {
    public static func live(weatherAPIKey: String, weatherAPIURL: String) -> any ForecastFeatureProviding {
        LiveForecastFeatureProvider(
            weatherAPIKey: weatherAPIKey,
            weatherAPIURL: weatherAPIURL
        )
    }
}

private extension LiveForecastFeatureProvider {
    static func liveService(weatherAPIKey: String, weatherAPIURL: String) -> LiveForecastFeatureService {
        let config = WeatherAPIConfig.weatherAPIDefault(apiKey: weatherAPIKey, apiUrl: weatherAPIURL)
        let client = URLSessionHTTPClient(session: URLSession.shared)
        let remoteDataSource = WeatherAPIRemoteDataSource(client: client, config: config)
        let dataSource = CachedWeatherRemoteDataSource(
            remoteDataSource: remoteDataSource,
            cachePolicy: .live
        )
        return LiveForecastFeatureService(dataSource: dataSource)
    }
}
