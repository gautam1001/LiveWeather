import Combine
import CurrentWeatherFeatureAPI
import ForecastFeatureAPI
import Foundation
import SearchFeatureAPI
import WeatherHomeFeatureAPI

@MainActor
public final class LiveWeatherHomeScreenViewModel: WeatherHomeScreenViewModeling {
    @Published public private(set) var state: WeatherHomeScreenState

    private let currentWeatherViewModel: any WeatherHomeCurrentWeatherFeature
    private let forecastProvider: any ForecastFeatureProviding
    private let searchProvider: any SearchFeatureProviding
    private let forecastDays: Int
    private var hasLoadedInitialData = false
    private var requestSequence = 0

    public init(
        currentWeatherViewModel: any WeatherHomeCurrentWeatherFeature,
        forecastProvider: any ForecastFeatureProviding,
        searchProvider: any SearchFeatureProviding,
        initialLocation: String = "New Delhi",
        forecastDays: Int = 5
    ) {
        self.currentWeatherViewModel = currentWeatherViewModel
        self.forecastProvider = forecastProvider
        self.searchProvider = searchProvider
        self.forecastDays = max(1, forecastDays)
        state = WeatherHomeScreenState(
            selectedLocation: initialLocation,
            searchQuery: initialLocation
        )
    }

    public func onAppear() async {
        guard !hasLoadedInitialData else {
            return
        }
        hasLoadedInitialData = true
        let requestID = beginRequest()
        await refreshWeather(for: requestID)
    }

    public func updateSearchQuery(_ query: String) {
        state.searchQuery = query
    }

    public func performSearch() async {
        let trimmedQuery = state.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            state.searchErrorMessage = nil
            return
        }

        let requestID = beginRequest()
        state.isSearching = true
        state.searchErrorMessage = nil
        defer {
            if shouldFinishSearch(for: requestID) {
                state.isSearching = false
            }
        }

        do {
            let results = try await searchProvider.search(query: trimmedQuery)
            guard shouldApplyResult(for: requestID) else {
                return
            }
            let resolvedLocation = results.first?.name ?? trimmedQuery
            state.selectedLocation = resolvedLocation
            state.searchQuery = resolvedLocation
            await refreshWeather(for: requestID)
        } catch is CancellationError {
            return
        } catch {
            guard shouldApplyResult(for: requestID) else {
                return
            }
            state.searchErrorMessage = error.localizedDescription
        }
    }

    public func selectLocation(_ location: String) async {
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLocation.isEmpty else {
            return
        }

        let requestID = beginRequest()
        state.selectedLocation = trimmedLocation
        state.searchQuery = trimmedLocation
        state.searchErrorMessage = nil
        await refreshWeather(for: requestID)
    }
}

private extension LiveWeatherHomeScreenViewModel {
    func beginRequest() -> Int {
        requestSequence += 1
        return requestSequence
    }

    func shouldApplyResult(for requestID: Int, location: String? = nil) -> Bool {
        guard requestID == requestSequence, !Task.isCancelled else {
            return false
        }

        guard let location else {
            return true
        }
        return state.selectedLocation == location
    }

    func shouldFinishSearch(for requestID: Int) -> Bool {
        requestID == requestSequence
    }

    func refreshWeather(for requestID: Int) async {
        let selectedLocation = state.selectedLocation
        state.currentWeatherState = .loading
        state.forecastState = .loading

        async let weatherState = loadCurrentWeatherState(for: selectedLocation)
        async let forecastState = loadForecastState(for: selectedLocation)

        let resolvedWeatherState = await weatherState
        let resolvedForecastState = await forecastState

        guard shouldApplyResult(for: requestID, location: selectedLocation) else {
            return
        }

        state.currentWeatherState = resolvedWeatherState
        state.forecastState = resolvedForecastState
    }

    func loadCurrentWeatherState(for location: String) async -> CurrentWeatherScreenState {
        await currentWeatherViewModel.fetchCurrentWeatherState(for: location)
    }

    func loadForecastState(for location: String) async -> WeatherHomeForecastState {
        do {
            let forecastDays = try await forecastProvider.fetchForecast(location: location, days: forecastDays)
            return .loaded(forecastDays)
        } catch {
            return .failed(error.localizedDescription)
        }
    }
}

public enum WeatherHomeFeatureFactory {
    @MainActor
    public static func live(
        currentWeatherViewModelFactory: @escaping CurrentWeatherViewModelFactory,
        forecastProvider: any ForecastFeatureProviding,
        searchProvider: any SearchFeatureProviding,
        initialLocation: String = "New Delhi",
        forecastDays: Int = 5
    ) -> LiveWeatherHomeScreenViewModel {
        LiveWeatherHomeScreenViewModel(
            currentWeatherViewModel: currentWeatherViewModelFactory(),
            forecastProvider: forecastProvider,
            searchProvider: searchProvider,
            initialLocation: initialLocation,
            forecastDays: forecastDays
        )
    }
}
