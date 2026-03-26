@testable import Data
@testable import Domain
import XCTest

final class WeatherRemoteRepositoryTests: XCTestCase {
    func testCurrentWeatherFetchRemoteSuccess() async throws {
        let weatherData = try FixtureLoader.loadData(named: "weatherapi_sample")
        let dto = try JSONDecoder().decode(ForecastResponseDTO.self, from: weatherData)
        let dataSource = MockWeatherAPIDataSource(dto: dto)
        let repository = WeatherRemoteRepository(dataSource: dataSource)
        let location = Location(name: "Pune", coordinate: Coordinate(latitude: 18.5204, longitude: 73.8567))
        let weatherNow = try await repository.getCurrentWeather(for: location)
        XCTAssertEqual(weatherNow.temperatureC, 28.5)
    }
}

final actor MockWeatherAPIDataSource: WeatherRemoteDataSource {
    let dto: ForecastResponseDTO
    init(dto: ForecastResponseDTO) {
        self.dto = dto
    }

    func fetchWeather(for _: Location) async throws -> ForecastResponseDTO {
        dto
    }
}
