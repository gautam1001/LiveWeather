//
//  WeatherRemoteDataSource.swift
//  Data
//
//  Created by Prashant Gautam on 22/03/26.
//

import Domain
import Foundation

public protocol WeatherRemoteDataSource: Sendable {
    func fetchWeather(for location: Location) async throws -> ForecastResponseDTO
}

public struct WeatherAPIRemoteDataSource: WeatherRemoteDataSource {
    private let client: HTTPClient
    private let config: WeatherAPIConfig

    public init(client: HTTPClient, config: WeatherAPIConfig) {
        self.client = client
        self.config = config
    }

    public func fetchWeather(for location: Location) async throws -> ForecastResponseDTO {
        let url = try buildURL(for: location.coordinate)
        let (data, response) = try await client.get(url: url)
        guard (200 ... 299).contains(response.statusCode) else {
            throw WeatherAPIError.httpStatus(response.statusCode)
        }
        do {
            return try JSONDecoder().decode(ForecastResponseDTO.self, from: data)
        } catch {
            throw WeatherAPIError.decodingFailed
        }
    }

    private func buildURL(for coordinate: Coordinate) throws -> URL {
        guard var components = URLComponents(url: config.baseURL, resolvingAgainstBaseURL: false) else {
            throw WeatherAPIError.invalidURL
        }

        let queryValue = "\(coordinate.latitude),\(coordinate.longitude)"
        var items: [URLQueryItem] = [
            URLQueryItem(name: "key", value: config.apiKey),
            URLQueryItem(name: "q", value: queryValue),
            URLQueryItem(name: "days", value: String(config.days)),
            URLQueryItem(name: "alerts", value: config.includeAlerts ? "yes" : "no"),
            URLQueryItem(name: "aqi", value: config.includeAQI ? "yes" : "no"),
        ]

        if let language = config.language {
            items.append(URLQueryItem(name: "lang", value: language))
        }

        components.queryItems = items
        guard let url = components.url else {
            throw WeatherAPIError.invalidURL
        }
        return url
    }
}
