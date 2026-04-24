import Combine
import CurrentWeatherFeatureAPI
import ForecastFeatureAPI
import SearchFeatureAPI

public enum WeatherHomeForecastState: Equatable, Sendable {
    case idle
    case loading
    case loaded([ForecastDay])
    case failed(String)
}

public struct WeatherHomeScreenState: Equatable, Sendable {
    public var selectedLocation: String
    public var searchQuery: String
    public var isSearching: Bool
    public var searchErrorMessage: String?
    public var currentWeatherState: CurrentWeatherScreenState
    public var forecastState: WeatherHomeForecastState

    public init(
        selectedLocation: String,
        searchQuery: String,
        isSearching: Bool = false,
        searchErrorMessage: String? = nil,
        currentWeatherState: CurrentWeatherScreenState = .idle,
        forecastState: WeatherHomeForecastState = .idle
    ) {
        self.selectedLocation = selectedLocation
        self.searchQuery = searchQuery
        self.isSearching = isSearching
        self.searchErrorMessage = searchErrorMessage
        self.currentWeatherState = currentWeatherState
        self.forecastState = forecastState
    }
}

public protocol WeatherHomeCurrentWeatherFeature: Sendable {
    func fetchCurrentWeatherState(for location: String) async -> CurrentWeatherScreenState
}

extension CurrentWeatherViewModel: WeatherHomeCurrentWeatherFeature {
    public func fetchCurrentWeatherState(for location: String) async -> CurrentWeatherScreenState {
        await loadWeather(for: location)
        return await MainActor.run { screenState }
    }
}

public protocol WeatherHomeScreenViewModeling: ObservableObject {
    @MainActor
    var state: WeatherHomeScreenState { get }
    @MainActor
    func onAppear() async
    @MainActor
    func updateSearchQuery(_ query: String)
    @MainActor
    func performSearch()
    @MainActor
    func cancelSearch()
    @MainActor
    func selectLocation(_ location: String) async
}
