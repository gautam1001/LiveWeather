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

@MainActor
public final class WeatherHomeSearchSectionModel: ObservableObject {
    @Published public var query: String
    @Published public var isSearching: Bool
    @Published public var errorMessage: String?

    public init(
        query: String,
        isSearching: Bool = false,
        errorMessage: String? = nil
    ) {
        self.query = query
        self.isSearching = isSearching
        self.errorMessage = errorMessage
    }
}

@MainActor
public final class WeatherHomeCurrentWeatherSectionModel: ObservableObject {
    @Published public var selectedLocation: String
    @Published public var state: CurrentWeatherScreenState

    public init(
        selectedLocation: String,
        state: CurrentWeatherScreenState = .idle
    ) {
        self.selectedLocation = selectedLocation
        self.state = state
    }
}

@MainActor
public final class WeatherHomeForecastSectionModel: ObservableObject {
    @Published public var state: WeatherHomeForecastState

    public init(state: WeatherHomeForecastState = .idle) {
        self.state = state
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
    var searchSectionModel: WeatherHomeSearchSectionModel { get }
    @MainActor
    var currentWeatherSectionModel: WeatherHomeCurrentWeatherSectionModel { get }
    @MainActor
    var forecastSectionModel: WeatherHomeForecastSectionModel { get }
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
