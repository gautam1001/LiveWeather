import Combine
import CurrentWeatherFeatureAPI
import ForecastFeatureAPI
import Foundation
import SearchFeatureAPI

public enum WeatherHomeForecastState: Equatable, Sendable {
    case idle
    case loading
    case loaded([ForecastDay])
    case failed(String)
}

public enum WeatherHomeCurrentWeatherViewState: Equatable, Sendable {
    case idle
    case loading
    case failed(message: String)
    case loaded(WeatherHomeCurrentWeatherViewData)
}

public struct WeatherHomeCurrentWeatherViewData: Equatable, Sendable {
    public let locationName: String
    public let temperatureText: String
    public let conditionSummary: String
    public let symbolName: String

    public init(
        locationName: String,
        temperatureText: String,
        conditionSummary: String,
        symbolName: String
    ) {
        self.locationName = locationName
        self.temperatureText = temperatureText
        self.conditionSummary = conditionSummary
        self.symbolName = symbolName
    }
}

public enum WeatherHomeForecastViewState: Equatable, Sendable {
    case idle
    case loading
    case failed(message: String)
    case loaded([WeatherHomeForecastRowViewData])
}

public struct WeatherHomeForecastRowViewData: Equatable, Sendable, Hashable {
    public let dateLabel: String
    public let summary: String
    public let temperatureText: String
    public let symbolName: String

    public init(
        dateLabel: String,
        summary: String,
        temperatureText: String,
        symbolName: String
    ) {
        self.dateLabel = dateLabel
        self.summary = summary
        self.temperatureText = temperatureText
        self.symbolName = symbolName
    }
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

    public var viewState: WeatherHomeCurrentWeatherViewState {
        switch state {
        case .idle:
            .idle
        case .loading:
            .loading
        case let .failed(message):
            .failed(message: message)
        case let .loaded(current):
            .loaded(
                WeatherHomeCurrentWeatherViewData(
                    locationName: selectedLocation,
                    temperatureText: String(format: "%.1f°", current.temperatureC),
                    conditionSummary: current.conditionSummary,
                    symbolName: WeatherHomeSymbolNameResolver.symbolName(for: current.conditionSummary)
                )
            )
        }
    }
}

@MainActor
public final class WeatherHomeForecastSectionModel: ObservableObject {
    @Published public var state: WeatherHomeForecastState

    public init(state: WeatherHomeForecastState = .idle) {
        self.state = state
    }

    public var viewState: WeatherHomeForecastViewState {
        switch state {
        case .idle:
            .idle
        case .loading:
            .loading
        case let .failed(message):
            .failed(message: message)
        case let .loaded(days):
            .loaded(
                days.map {
                    WeatherHomeForecastRowViewData(
                        dateLabel: $0.dateLabel,
                        summary: $0.summary,
                        temperatureText: String(format: "%.0f°", $0.temperatureC),
                        symbolName: WeatherHomeSymbolNameResolver.symbolName(for: $0.summary)
                    )
                }
            )
        }
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

private enum WeatherHomeSymbolNameResolver {
    static func symbolName(for summary: String) -> String {
        let lower = summary.lowercased()
        if lower.contains("sun") {
            return "sun.max.fill"
        }
        if lower.contains("rain") {
            return "cloud.rain.fill"
        }
        if lower.contains("cloud") {
            return "cloud.fill"
        }
        return "cloud.sun.fill"
    }
}
