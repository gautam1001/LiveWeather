import CurrentWeatherFeatureAPI
import ForecastFeatureAPI
import SearchFeatureAPI
import WeatherHomeFeatureAPI
import WeatherHomeFeatureImpl
import XCTest

@MainActor
final class WeatherHomeFeatureTests: XCTestCase {
    func testOnAppearLoadsCurrentWeatherAndForecastForInitialLocation() async {
        let currentWeatherSpy = CurrentWeatherFeatureSpy(
            stateByLocation: [
                "New Delhi": .loaded(
                    CurrentWeatherDisplay(
                        conditionSummary: "Sunny",
                        temperatureC: 31
                    )
                ),
            ]
        )
        let forecastSpy = ForecastProviderSpy(
            stubbedDays: [
                ForecastDay(dateLabel: "Fri, 11 Apr", temperatureC: 31, summary: "Sunny"),
            ]
        )
        let searchSpy = SearchProviderSpy(stubbedResults: [SearchLocation(name: "New Delhi")])

        let viewModel = LiveWeatherHomeScreenViewModel(
            currentWeatherViewModel: currentWeatherSpy,
            forecastProvider: forecastSpy,
            searchProvider: searchSpy
        )

        await viewModel.onAppear()

        let loadedLocations = await currentWeatherSpy.loadedLocations()
        XCTAssertEqual(loadedLocations, ["New Delhi"])
        XCTAssertEqual(viewModel.state.selectedLocation, "New Delhi")
        XCTAssertEqual(viewModel.state.searchQuery, "New Delhi")
        XCTAssertEqual(
            viewModel.state.currentWeatherState,
            .loaded(CurrentWeatherDisplay(conditionSummary: "Sunny", temperatureC: 31))
        )
        if case let .loaded(days) = viewModel.state.forecastState {
            XCTAssertEqual(days.count, 1)
            XCTAssertEqual(days.first?.summary, "Sunny")
        } else {
            XCTFail("Expected forecast loaded state")
        }

        let call = await forecastSpy.lastCall()
        XCTAssertEqual(call?.location, "New Delhi")
        XCTAssertEqual(call?.days, 5)
    }

    func testOnAppearLoadsOnlyOnce() async {
        let currentWeatherSpy = CurrentWeatherFeatureSpy(
            stateByLocation: [
                "New Delhi": .loaded(
                    CurrentWeatherDisplay(conditionSummary: "Clear", temperatureC: 26)
                ),
            ]
        )
        let forecastSpy = ForecastProviderSpy(
            stubbedDays: [ForecastDay(dateLabel: "Sat, 12 Apr", temperatureC: 26, summary: "Clear")]
        )
        let searchSpy = SearchProviderSpy(stubbedResults: [])
        let viewModel = LiveWeatherHomeScreenViewModel(
            currentWeatherViewModel: currentWeatherSpy,
            forecastProvider: forecastSpy,
            searchProvider: searchSpy
        )

        await viewModel.onAppear()
        await viewModel.onAppear()

        let loadedLocations = await currentWeatherSpy.loadedLocations()
        XCTAssertEqual(loadedLocations.count, 1)
        let callCount = await forecastSpy.callCount()
        XCTAssertEqual(callCount, 1)
    }

    func testPerformSearchSuccessUpdatesLocationAndRefreshesStates() async {
        let currentWeatherSpy = CurrentWeatherFeatureSpy(
            stateByLocation: [
                "New Delhi": .loaded(
                    CurrentWeatherDisplay(conditionSummary: "Clear", temperatureC: 25)
                ),
                "Pune": .loaded(
                    CurrentWeatherDisplay(conditionSummary: "Cloudy", temperatureC: 28)
                ),
            ]
        )
        let forecastSpy = ForecastProviderSpy(
            stubbedDays: [ForecastDay(dateLabel: "Sun, 13 Apr", temperatureC: 28, summary: "Cloudy")]
        )
        let searchSpy = SearchProviderSpy(stubbedResults: [SearchLocation(name: "Pune")])
        let viewModel = LiveWeatherHomeScreenViewModel(
            currentWeatherViewModel: currentWeatherSpy,
            forecastProvider: forecastSpy,
            searchProvider: searchSpy
        )

        viewModel.updateSearchQuery("  Pune ")
        viewModel.performSearch()
        await waitForSearchToFinish(in: viewModel)

        XCTAssertEqual(viewModel.state.selectedLocation, "Pune")
        XCTAssertEqual(viewModel.state.searchQuery, "Pune")
        XCTAssertFalse(viewModel.state.isSearching)
        XCTAssertNil(viewModel.state.searchErrorMessage)
        let loadedLocations = await currentWeatherSpy.loadedLocations()
        XCTAssertEqual(loadedLocations.last, "Pune")
        let query = await searchSpy.lastQuery()
        XCTAssertEqual(query, "Pune")
    }

    func testPerformSearchFailureShowsErrorAndSkipsRefresh() async {
        let currentWeatherSpy = CurrentWeatherFeatureSpy(stateByLocation: [:])
        let forecastSpy = ForecastProviderSpy(stubbedDays: [])
        let searchSpy = SearchProviderSpy(
            stubbedResults: [],
            stubbedError: SearchProviderTestError.expected
        )
        let viewModel = LiveWeatherHomeScreenViewModel(
            currentWeatherViewModel: currentWeatherSpy,
            forecastProvider: forecastSpy,
            searchProvider: searchSpy
        )

        viewModel.updateSearchQuery("error")
        viewModel.performSearch()
        await waitForSearchToFinish(in: viewModel)

        XCTAssertFalse(viewModel.state.isSearching)
        XCTAssertNotNil(viewModel.state.searchErrorMessage)
        let loadedLocations = await currentWeatherSpy.loadedLocations()
        XCTAssertEqual(loadedLocations.count, 0)
        let forecastCalls = await forecastSpy.callCount()
        XCTAssertEqual(forecastCalls, 0)
    }

    func testSelectLocationRefreshesCurrentWeatherAndForecast() async {
        let currentWeatherSpy = CurrentWeatherFeatureSpy(
            stateByLocation: [
                "Mumbai": .loaded(
                    CurrentWeatherDisplay(conditionSummary: "Rain", temperatureC: 24)
                ),
            ]
        )
        let forecastSpy = ForecastProviderSpy(
            stubbedDays: [ForecastDay(dateLabel: "Mon, 14 Apr", temperatureC: 24, summary: "Rain")]
        )
        let searchSpy = SearchProviderSpy(stubbedResults: [])
        let viewModel = LiveWeatherHomeScreenViewModel(
            currentWeatherViewModel: currentWeatherSpy,
            forecastProvider: forecastSpy,
            searchProvider: searchSpy
        )

        await viewModel.selectLocation("Mumbai")

        XCTAssertEqual(viewModel.state.selectedLocation, "Mumbai")
        XCTAssertEqual(viewModel.state.searchQuery, "Mumbai")
        let loadedLocations = await currentWeatherSpy.loadedLocations()
        XCTAssertEqual(loadedLocations, ["Mumbai"])
        let call = await forecastSpy.lastCall()
        XCTAssertEqual(call?.location, "Mumbai")
    }

    func testLatestSelectionWinsWhenRefreshesOverlap() async {
        let currentWeatherSpy = CurrentWeatherFeatureSpy(
            stateByLocation: [
                "Pune": .loaded(
                    CurrentWeatherDisplay(conditionSummary: "Rain", temperatureC: 24)
                ),
                "Mumbai": .loaded(
                    CurrentWeatherDisplay(conditionSummary: "Sunny", temperatureC: 31)
                ),
            ],
            delayByLocation: ["Pune": 200_000_000]
        )
        let forecastSpy = ForecastProviderSpy(
            stubbedDays: [],
            stubbedDaysByLocation: [
                "Pune": [ForecastDay(dateLabel: "Tue, 15 Apr", temperatureC: 24, summary: "Rain")],
                "Mumbai": [ForecastDay(dateLabel: "Tue, 15 Apr", temperatureC: 31, summary: "Sunny")],
            ],
            delayByLocation: ["Pune": 200_000_000]
        )
        let searchSpy = SearchProviderSpy(stubbedResults: [])
        let viewModel = LiveWeatherHomeScreenViewModel(
            currentWeatherViewModel: currentWeatherSpy,
            forecastProvider: forecastSpy,
            searchProvider: searchSpy
        )

        let firstSelection = Task {
            await viewModel.selectLocation("Pune")
        }
        await Task.yield()
        let secondSelection = Task {
            await viewModel.selectLocation("Mumbai")
        }

        await firstSelection.value
        await secondSelection.value

        XCTAssertEqual(viewModel.state.selectedLocation, "Mumbai")
        XCTAssertEqual(
            viewModel.state.currentWeatherState,
            .loaded(CurrentWeatherDisplay(conditionSummary: "Sunny", temperatureC: 31))
        )
        if case let .loaded(days) = viewModel.state.forecastState {
            XCTAssertEqual(days.first?.summary, "Sunny")
        } else {
            XCTFail("Expected forecast loaded state")
        }
    }

    func testPerformSearchCancelsPreviousInFlightTask() async {
        let currentWeatherSpy = CurrentWeatherFeatureSpy(
            stateByLocation: [
                "Pune": .loaded(
                    CurrentWeatherDisplay(conditionSummary: "Rain", temperatureC: 24)
                ),
                "Mumbai": .loaded(
                    CurrentWeatherDisplay(conditionSummary: "Sunny", temperatureC: 31)
                ),
            ]
        )
        let forecastSpy = ForecastProviderSpy(
            stubbedDays: [],
            stubbedDaysByLocation: [
                "Pune": [ForecastDay(dateLabel: "Tue, 15 Apr", temperatureC: 24, summary: "Rain")],
                "Mumbai": [ForecastDay(dateLabel: "Tue, 15 Apr", temperatureC: 31, summary: "Sunny")],
            ]
        )
        let searchSpy = SearchProviderSpy(
            stubbedResults: [],
            stubbedResultsByQuery: [
                "Pune": [SearchLocation(name: "Pune")],
                "Mumbai": [SearchLocation(name: "Mumbai")],
            ],
            delayByQuery: ["Pune": 200_000_000]
        )
        let viewModel = LiveWeatherHomeScreenViewModel(
            currentWeatherViewModel: currentWeatherSpy,
            forecastProvider: forecastSpy,
            searchProvider: searchSpy
        )

        viewModel.updateSearchQuery("Pune")
        viewModel.performSearch()
        await Task.yield()

        viewModel.updateSearchQuery("Mumbai")
        viewModel.performSearch()
        await waitForSearchToFinish(in: viewModel)

        XCTAssertEqual(viewModel.state.selectedLocation, "Mumbai")
        XCTAssertEqual(viewModel.state.searchQuery, "Mumbai")
        let cancellationCount = await searchSpy.cancellationCount()
        XCTAssertEqual(cancellationCount, 1)
    }
}

private actor CurrentWeatherFeatureSpy: WeatherHomeCurrentWeatherFeature {
    private let stateByLocation: [String: CurrentWeatherScreenState]
    private let delayByLocation: [String: UInt64]
    private var loadedLocationsStore: [String] = []

    init(
        stateByLocation: [String: CurrentWeatherScreenState],
        delayByLocation: [String: UInt64] = [:]
    ) {
        self.stateByLocation = stateByLocation
        self.delayByLocation = delayByLocation
    }

    func fetchCurrentWeatherState(for location: String) async -> CurrentWeatherScreenState {
        loadedLocationsStore.append(location)
        if let delay = delayByLocation[location] {
            try? await Task.sleep(nanoseconds: delay)
        }
        if let next = stateByLocation[location] {
            return next
        }
        return .failed("No stub for \(location)")
    }

    func loadedLocations() -> [String] {
        loadedLocationsStore
    }
}

private enum SearchProviderTestError: Error {
    case expected
}

private actor SearchProviderSpy: SearchFeatureProviding {
    private let stubbedResults: [SearchLocation]
    private let stubbedResultsByQuery: [String: [SearchLocation]]
    private let stubbedError: Error?
    private let delayByQuery: [String: UInt64]
    private var queries: [String] = []
    private var cancellationCountStore = 0

    init(
        stubbedResults: [SearchLocation],
        stubbedResultsByQuery: [String: [SearchLocation]] = [:],
        stubbedError: Error? = nil,
        delayByQuery: [String: UInt64] = [:]
    ) {
        self.stubbedResults = stubbedResults
        self.stubbedResultsByQuery = stubbedResultsByQuery
        self.stubbedError = stubbedError
        self.delayByQuery = delayByQuery
    }

    func search(query: String) async throws -> [SearchLocation] {
        queries.append(query)
        do {
            if let delay = delayByQuery[query] {
                try await Task.sleep(nanoseconds: delay)
            }
        } catch is CancellationError {
            cancellationCountStore += 1
            throw CancellationError()
        }
        if let stubbedError {
            throw stubbedError
        }
        return stubbedResultsByQuery[query] ?? stubbedResults
    }

    func lastQuery() -> String? {
        queries.last
    }

    func cancellationCount() -> Int {
        cancellationCountStore
    }
}

private actor ForecastProviderSpy: ForecastFeatureProviding {
    struct Call: Equatable {
        let location: String
        let days: Int
    }

    private let stubbedDays: [ForecastDay]
    private let stubbedDaysByLocation: [String: [ForecastDay]]
    private let stubbedError: Error?
    private let delayByLocation: [String: UInt64]
    private var calls: [Call] = []

    init(
        stubbedDays: [ForecastDay],
        stubbedDaysByLocation: [String: [ForecastDay]] = [:],
        stubbedError: Error? = nil,
        delayByLocation: [String: UInt64] = [:]
    ) {
        self.stubbedDays = stubbedDays
        self.stubbedDaysByLocation = stubbedDaysByLocation
        self.stubbedError = stubbedError
        self.delayByLocation = delayByLocation
    }

    func fetchForecast(location: String, days: Int) async throws -> [ForecastDay] {
        calls.append(Call(location: location, days: days))
        if let delay = delayByLocation[location] {
            try? await Task.sleep(nanoseconds: delay)
        }
        if let stubbedError {
            throw stubbedError
        }
        return stubbedDaysByLocation[location] ?? stubbedDays
    }

    func lastCall() -> Call? {
        calls.last
    }

    func callCount() -> Int {
        calls.count
    }
}

@MainActor
private func waitForSearchToFinish(
    in viewModel: LiveWeatherHomeScreenViewModel,
    timeoutNanoseconds: UInt64 = 1_000_000_000
) async {
    let deadline = DispatchTime.now().uptimeNanoseconds + timeoutNanoseconds
    while viewModel.state.isSearching, DispatchTime.now().uptimeNanoseconds < deadline {
        try? await Task.sleep(nanoseconds: 10_000_000)
    }
}
