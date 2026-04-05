import Foundation
import Data
import Domain
import Presentation

public final class LiveCurrentWeatherFeatureProvider {
    public typealias WeatherRepositoryFactory = (_ apiKey: String, _ apiURL: String) -> WeatherRepository

    private let repository: WeatherRepository

    public convenience init(weatherAPIKey: String, weatherAPIURL: String) {
        self.init(
            weatherAPIKey: weatherAPIKey,
            weatherAPIURL: weatherAPIURL,
            repositoryFactory: LiveCurrentWeatherFeatureProvider.liveRepositoryFactory
        )
    }

    public init(
        weatherAPIKey: String,
        weatherAPIURL: String,
        repositoryFactory: WeatherRepositoryFactory
    ) {
        repository = repositoryFactory(weatherAPIKey, weatherAPIURL)
    }

    public func makeWeatherViewModel() -> WeatherOverviewViewModel {
        WeatherOverviewViewModel(usecase: CurrentWeatherUsecase(repository: repository))
    }

    private static func liveRepositoryFactory(apiKey: String, apiURL: String) -> WeatherRepository {
        let config = WeatherAPIConfig.weatherAPIDefault(apiKey: apiKey, apiUrl: apiURL)
        let client = URLSessionHTTPClient(session: URLSession.shared)
        let dataSource = WeatherAPIRemoteDataSource(client: client, config: config)
        return WeatherRemoteRepository(dataSource: dataSource)
    }
}
