import Combine
import Domain
import Foundation

public final class WeatherOverviewViewModel: ObservableObject, @unchecked Sendable {
    @Published public private(set) var state: State = .idle

    private let useCase: CurrentWeatherUsecase

    public init(usecase: CurrentWeatherUsecase) {
        useCase = usecase
    }

    public func load(for location: String) async {
        await MainActor.run {
            state = .loading
        }

        let requestedLocation = Location(
            name: location,
            coordinate: Coordinate(latitude: 28.644800, longitude: 77.216721)
        )
        let useCase = useCase

        do {
            // Run repository/network work off the main actor and hop back only for UI state updates.
            let current = try await Task.detached(priority: .userInitiated) {
                try await useCase(location: requestedLocation)
            }.value
            let overview = WeatherOverview(locationName: requestedLocation.name, current: current)
            await MainActor.run {
                state = .loaded(overview)
            }
        } catch {
            await MainActor.run {
                state = .failed(error.localizedDescription)
            }
        }
    }
}

public extension WeatherOverviewViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded(WeatherOverview)
        case failed(String)
    }

    struct WeatherOverview: Equatable {
        public let locationName: String
        public let current: WeatherNow

        public init(locationName: String, current: WeatherNow) {
            self.locationName = locationName
            self.current = current
        }
    }
}
