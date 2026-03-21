import Combine
import Foundation
import Domain

public final class WeatherOverviewViewModel: ObservableObject {
    
    @Published public private(set) var state: State = .idle
    
    private let useCase: CurrentWeatherUsecase
    
    public init(usecase: CurrentWeatherUsecase) {
        self.useCase = usecase
    }
    
    @MainActor
    public func load(for location: String) async {
        self.state = .loading
        do {
            let current = try await useCase(location: location)
            let overview = WeatherOverview(locationName: location, current: current)
            self.state = .loaded(overview)
        } catch {
            self.state = .failed(error.localizedDescription)
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
