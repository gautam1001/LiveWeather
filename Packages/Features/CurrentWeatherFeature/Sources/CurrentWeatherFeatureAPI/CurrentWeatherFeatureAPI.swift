import Presentation

public typealias CurrentWeatherViewModel = WeatherOverviewViewModel

public struct CurrentWeatherDisplay: Equatable, Sendable {
    public let conditionSummary: String
    public let temperatureC: Double

    public init(conditionSummary: String, temperatureC: Double) {
        self.conditionSummary = conditionSummary
        self.temperatureC = temperatureC
    }
}

public enum CurrentWeatherScreenState: Equatable, Sendable {
    case idle
    case loading
    case loaded(CurrentWeatherDisplay)
    case failed(String)
}

public typealias CurrentWeatherViewModelFactory = () -> CurrentWeatherViewModel

public extension CurrentWeatherViewModel {
    func loadWeather(for location: String) async {
        await load(for: location)
    }

    @MainActor
    var screenState: CurrentWeatherScreenState {
        switch state {
        case .idle:
            .idle
        case .loading:
            .loading
        case let .loaded(overview):
            .loaded(
                CurrentWeatherDisplay(
                    conditionSummary: overview.current.conditionSummary,
                    temperatureC: overview.current.temperatureC
                )
            )
        case let .failed(message):
            .failed(message)
        }
    }
}

public protocol CurrentWeatherFeatureProviding {
    func makeWeatherViewModel() -> CurrentWeatherViewModel
}
