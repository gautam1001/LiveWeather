import Combine
import CurrentWeatherFeatureAPI
import ForecastFeatureAPI
import Foundation
import SearchFeatureAPI
import WeatherHomeFeatureAPI

public final class LiveWeatherHomeScreenViewModel: WeatherHomeScreenViewModeling {
    @MainActor @Published public private(set) var state: WeatherHomeScreenState

    private let currentWeatherViewModel: any WeatherHomeCurrentWeatherFeature
    private let forecastProvider: any ForecastFeatureProviding
    private let searchProvider: any SearchFeatureProviding
    private let forecastDays: Int
    @MainActor private var hasLoadedInitialData = false
    @MainActor private var requestSequence = 0
    @MainActor private var activeSearchRequestID: Int?
    @MainActor private var activeSearchTask: Task<Void, Never>?

    @MainActor
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

    @MainActor
    public func onAppear() async {
        guard !hasLoadedInitialData else {
            return
        }
        hasLoadedInitialData = true
        let requestID = beginRequest()
        await refreshWeather(for: requestID)
    }

    @MainActor
    public func updateSearchQuery(_ query: String) {
        state.searchQuery = query
    }

    @MainActor
    public func performSearch() {
        let trimmedQuery = state.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            state.searchErrorMessage = nil
            return
        }

        cancelActiveSearch(resetSearchState: false)
        let requestID = beginRequest()
        activeSearchRequestID = requestID
        state.isSearching = true
        state.searchErrorMessage = nil
        let searchProvider = searchProvider
        activeSearchTask = Task { [weak self, searchProvider] in
            do {
                let results = try await searchProvider.search(query: trimmedQuery)
                await self?.applySearchResults(
                    results,
                    fallbackQuery: trimmedQuery,
                    requestID: requestID
                )
            } catch is CancellationError {
                await self?.finishSearchIfCurrent(requestID: requestID)
                return
            } catch {
                await self?.applySearchFailure(error, requestID: requestID)
            }

            await self?.finishSearchIfCurrent(requestID: requestID)
        }
    }

    @MainActor
    public func cancelSearch() {
        cancelActiveSearch(resetSearchState: true)
    }

    @MainActor
    public func selectLocation(_ location: String) async {
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLocation.isEmpty else {
            return
        }

        cancelActiveSearch(resetSearchState: true)
        let requestID = beginRequest()
        state.selectedLocation = trimmedLocation
        state.searchQuery = trimmedLocation
        state.searchErrorMessage = nil
        await refreshWeather(for: requestID)
    }
}

private extension LiveWeatherHomeScreenViewModel {
    @MainActor
    func beginRequest() -> Int {
        requestSequence += 1
        return requestSequence
    }

    @MainActor
    func shouldApplyResult(for requestID: Int, location: String? = nil) -> Bool {
        guard requestID == requestSequence, !Task.isCancelled else {
            return false
        }

        guard let location else {
            return true
        }
        return state.selectedLocation == location
    }

    @MainActor
    func finishSearchIfCurrent(requestID: Int) async {
        guard activeSearchRequestID == requestID else {
            return
        }

        activeSearchTask = nil
        activeSearchRequestID = nil
        state.isSearching = false
    }

    @MainActor
    func cancelActiveSearch(resetSearchState: Bool) {
        activeSearchTask?.cancel()
        activeSearchTask = nil
        activeSearchRequestID = nil
        if resetSearchState {
            state.isSearching = false
        }
    }

    @MainActor
    func applySearchResults(
        _ results: [SearchLocation],
        fallbackQuery: String,
        requestID: Int
    ) async {
        guard shouldApplyResult(for: requestID) else {
            return
        }

        let resolvedLocation = results.first?.name ?? fallbackQuery
        state.selectedLocation = resolvedLocation
        state.searchQuery = resolvedLocation
        await refreshWeather(for: requestID)
    }

    @MainActor
    func applySearchFailure(_ error: Error, requestID: Int) async {
        guard shouldApplyResult(for: requestID) else {
            return
        }
        state.searchErrorMessage = error.localizedDescription
    }

    @MainActor
    func refreshWeather(for requestID: Int) async {
        let selectedLocation = state.selectedLocation
        let currentWeatherViewModel = currentWeatherViewModel
        let forecastProvider = forecastProvider
        let requestedForecastDays = forecastDays
        state.currentWeatherState = .loading
        state.forecastState = .loading

        async let weatherState = currentWeatherViewModel.fetchCurrentWeatherState(for: selectedLocation)
        async let forecastState = Self.loadForecastState(
            using: forecastProvider,
            location: selectedLocation,
            days: requestedForecastDays
        )

        let resolvedWeatherState = await weatherState
        let resolvedForecastState = await forecastState

        guard shouldApplyResult(for: requestID, location: selectedLocation) else {
            return
        }

        state.currentWeatherState = resolvedWeatherState
        state.forecastState = resolvedForecastState
    }

    static func loadForecastState(
        using forecastProvider: any ForecastFeatureProviding,
        location: String,
        days: Int
    ) async -> WeatherHomeForecastState {
        do {
            let forecastDays = try await forecastProvider.fetchForecast(location: location, days: days)
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
