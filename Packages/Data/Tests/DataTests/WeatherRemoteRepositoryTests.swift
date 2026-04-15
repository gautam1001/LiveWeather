@testable import Data
@testable import Domain
import XCTest

final class WeatherRemoteRepositoryTests: XCTestCase {
    func testCurrentWeatherFetchRemoteSuccess() async throws {
        let weatherData = try FixtureLoader.loadData(named: "weatherapi_sample")
        let dto = try JSONDecoder().decode(CurrentWeatherResponseDTO.self, from: weatherData)
        let dataSource = MockWeatherAPIDataSource(currentDTO: dto)
        let repository = WeatherRemoteRepository(dataSource: dataSource)
        let location = Location(name: "Pune", coordinate: Coordinate(latitude: 18.5204, longitude: 73.8567))
        let weatherNow = try await repository.getCurrentWeather(for: location)
        XCTAssertEqual(weatherNow.temperatureC, 28.5)
    }
}

final actor MockWeatherAPIDataSource: WeatherRemoteDataSource {
    let currentDTO: CurrentWeatherResponseDTO

    init(currentDTO: CurrentWeatherResponseDTO) {
        self.currentDTO = currentDTO
    }

    func fetchWeather(for _: Location) async throws -> CurrentWeatherResponseDTO {
        currentDTO
    }

    func fetchForecast(for _: String, days _: Int) async throws -> ForecastResponseDTO {
        ForecastResponseDTO(forecast: ForecastDTO(forecastDay: []))
    }
}
