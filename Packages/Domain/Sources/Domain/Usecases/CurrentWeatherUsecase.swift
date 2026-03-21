
import Foundation

public struct CurrentWeatherUsecase: Sendable {
    
    private let repository: WeatherRepository
    
    public init(repository: WeatherRepository) {
        self.repository = repository
    }
    
    public func callAsFunction(location: String) async throws -> WeatherNow {
        try await self.repository.getCurrentWeather(for: location)
    }
}
