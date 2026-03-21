import Foundation
import Domain

public final class WeatherRemoteRepository: WeatherRepository {
   public init() {}
   public func getCurrentWeather(for location: String) async throws -> WeatherNow {
        return WeatherNow(temperatureC: 0.0, conditionCode: 1, conditionSummary: "Rainy Day", conditionDescription: "Clear to partly cloudy; air quality will be very unhealthy")
    }
    
}

