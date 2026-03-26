import Foundation

public struct CurrentWeatherUsecase: Sendable {
    private let repository: WeatherRepository

    public init(repository: WeatherRepository) {
        self.repository = repository
    }

    public func callAsFunction(location: Location) async throws -> WeatherNow {
        try await repository.getCurrentWeather(for: location)
    }
}
