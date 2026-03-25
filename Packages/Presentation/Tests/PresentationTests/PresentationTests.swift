import Foundation
import Testing
import Domain
@testable import Presentation

@MainActor
@Test("WeatherOverviewViewModel starts in idle state")
func viewModelStartsIdle() {
    let repository = WeatherRepositoryStub(result: .success(sampleWeather))
    let useCase = CurrentWeatherUsecase(repository: repository)
    let viewModel = WeatherOverviewViewModel(usecase: useCase)

    #expect(viewModel.state == .idle)
}

@MainActor
@Test("load(for:) sets loaded state on success")
func loadSetsLoadedStateOnSuccess() async {
    let repository = WeatherRepositoryStub(result: .success(sampleWeather))
    let useCase = CurrentWeatherUsecase(repository: repository)
    let viewModel = WeatherOverviewViewModel(usecase: useCase)

    await viewModel.load(for: "Noida")

    switch viewModel.state {
    case .loaded(let overview):
        #expect(overview.locationName == "Noida")
        #expect(overview.current == sampleWeather)
    default:
        Issue.record("Expected loaded state after successful fetch")
    }

    let requested = await repository.lastRequestedLocation()
    #expect(requested?.name == "Noida")
    #expect(requested?.coordinate.latitude == 28.644800)
    #expect(requested?.coordinate.longitude == 77.216721)
}

@MainActor
@Test("load(for:) sets failed state on error")
func loadSetsFailedStateOnError() async {
    let repository = WeatherRepositoryStub(result: .failure(TestError.upstream))
    let useCase = CurrentWeatherUsecase(repository: repository)
    let viewModel = WeatherOverviewViewModel(usecase: useCase)

    await viewModel.load(for: "Pune")

    switch viewModel.state {
    case .failed(let message):
        #expect(message == TestError.upstream.localizedDescription)
    default:
        Issue.record("Expected failed state after repository error")
    }

    let requested = await repository.lastRequestedLocation()
    #expect(requested?.name == "Pune")
}

private let sampleWeather = WeatherNow(
    temperatureC: 27.4,
    conditionCode: 1003,
    conditionSummary: "Partly cloudy",
    conditionDescription: "partly cloudy"
)

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

private enum TestError: LocalizedError {
    case upstream

    var errorDescription: String? {
        switch self {
        case .upstream:
            return "Unable to fetch weather data"
        }
    }
}
