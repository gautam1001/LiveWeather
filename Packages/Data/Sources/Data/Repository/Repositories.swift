import Foundation
import Domain

public final class WeatherRemoteRepository: WeatherRepository {
    
    private let dataSource: WeatherRemoteDataSource
    private let mapper: WeatherAPIMapper
    
    public init(dataSource: WeatherRemoteDataSource,
                mapper: WeatherAPIMapper = WeatherAPIMapper()) {
        self.dataSource = dataSource
        self.mapper = mapper
    }
    
   public func getCurrentWeather(for location: Location) async throws -> WeatherNow {
      
       let dto = try await dataSource.fetchWeather(for: location)
       let weather = try mapper.mapCurrent(dto)
       return weather
    }
    
}

