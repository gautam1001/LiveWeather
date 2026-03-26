@testable import Domain
import Foundation
import Testing

@Test("CurrentWeatherUsecase returns weather on repository success")
func currentWeatherUsecaseReturnsResult() async throws {
    let location = Location(
        name: "Pune",
        coordinate: Coordinate(latitude: 18.5204, longitude: 73.8567)
    )
    let expected = WeatherNow(
        temperatureC: 29.0,
        conditionCode: 1000,
        conditionSummary: "Clear",
        conditionDescription: "clear sky"
    )
    let repository = WeatherRepositoryStub(result: .success(expected))
    let usecase = CurrentWeatherUsecase(repository: repository)

    let result = try await usecase(location: location)

    #expect(result == expected)
    #expect(await repository.lastRequestedLocation() == location)
}

@Test("CurrentWeatherUsecase propagates repository failure")
func currentWeatherUsecasePropagatesFailure() async {
    let location = Location(
        name: "Delhi",
        coordinate: Coordinate(latitude: 28.6139, longitude: 77.2090)
    )
    let repository = WeatherRepositoryStub(result: .failure(TestError.upstream))
    let usecase = CurrentWeatherUsecase(repository: repository)

    do {
        _ = try await usecase(location: location)
        Issue.record("Expected error, but call succeeded")
    } catch {
        #expect(error as? TestError == .upstream)
    }

    #expect(await repository.lastRequestedLocation() == location)
}

@Test("Location stores custom id, name, and coordinate")
func locationStoresValues() {
    let id = UUID()
    let coordinate = Coordinate(latitude: 12.9716, longitude: 77.5946)

    let location = Location(id: id, name: "Bengaluru", coordinate: coordinate)

    #expect(location.id == id)
    #expect(location.name == "Bengaluru")
    #expect(location.coordinate == coordinate)
}

@Test("Location generates unique IDs by default")
func locationGeneratesUniqueIDs() {
    let first = Location(name: "City A", coordinate: Coordinate(latitude: 1, longitude: 1))
    let second = Location(name: "City B", coordinate: Coordinate(latitude: 2, longitude: 2))

    #expect(first.id != second.id)
}

@Test("WeatherNow equality compares all values")
func weatherNowEquality() {
    let baseline = WeatherNow(
        temperatureC: 31.5,
        conditionCode: 1100,
        conditionSummary: "Sunny",
        conditionDescription: "sunny"
    )
    let same = WeatherNow(
        temperatureC: 31.5,
        conditionCode: 1100,
        conditionSummary: "Sunny",
        conditionDescription: "sunny"
    )
    let different = WeatherNow(
        temperatureC: 31.5,
        conditionCode: 1200,
        conditionSummary: "Cloudy",
        conditionDescription: "overcast"
    )

    #expect(baseline == same)
    #expect(baseline != different)
}

private actor WeatherRepositoryStub: WeatherRepository {
    private let result: Result<WeatherNow, Error>
    private var requestedLocations: [Location] = []

    init(result: Result<WeatherNow, Error>) {
        self.result = result
    }

    func getCurrentWeather(for location: Location) async throws -> WeatherNow {
        requestedLocations.append(location)
        return try result.get()
    }

    func lastRequestedLocation() -> Location? {
        requestedLocations.last
    }
}

private enum TestError: Error, Equatable {
    case upstream
}
