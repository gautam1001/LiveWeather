import CurrentWeatherFeatureAPI
import Data
import Domain
import Foundation
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
        let remoteDataSource = WeatherAPIRemoteDataSource(client: client, config: config)
        let dataSource = CachedWeatherRemoteDataSource(
            remoteDataSource: remoteDataSource,
            cachePolicy: .live
        )
        return WeatherRemoteRepository(dataSource: dataSource)
    }
}

extension LiveCurrentWeatherFeatureProvider: CurrentWeatherFeatureProviding {}

public enum CurrentWeatherFeatureFactory {
    public static func live(
        weatherAPIKey: String,
        weatherAPIURL: String
    ) -> any CurrentWeatherFeatureProviding {
        LiveCurrentWeatherFeatureProvider(
            weatherAPIKey: weatherAPIKey,
            weatherAPIURL: weatherAPIURL
        )
    }

    public static func liveViewModelFactory(
        weatherAPIKey: String,
        weatherAPIURL: String
    ) -> CurrentWeatherViewModelFactory {
        let provider = live(weatherAPIKey: weatherAPIKey, weatherAPIURL: weatherAPIURL)
        return {
            provider.makeWeatherViewModel()
        }
    }
}
