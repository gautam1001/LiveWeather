//
//  WeatherRemoteDataSource.swift
//  Data
//
//  Created by Prashant Gautam on 22/03/26.
//

import Domain
import Foundation

public protocol WeatherRemoteDataSource: Sendable {
    func fetchWeather(for location: Location) async throws -> CurrentWeatherResponseDTO
    func fetchForecast(for location: String, days: Int) async throws -> ForecastResponseDTO
}

public struct WeatherAPIRemoteDataSource: WeatherRemoteDataSource {
    private let client: HTTPClient
    private let config: WeatherAPIConfig

    public init(client: HTTPClient, config: WeatherAPIConfig) {
        self.client = client
        self.config = config
    }

    public func fetchWeather(for location: Location) async throws -> CurrentWeatherResponseDTO {
        let url = try buildCurrentWeatherURL(for: location)
        return try await performRequest(url: url, as: CurrentWeatherResponseDTO.self)
    }

    public func fetchForecast(for location: String, days: Int) async throws -> ForecastResponseDTO {
        let url = try buildForecastURL(for: location, days: days)
        return try await performRequest(url: url, as: ForecastResponseDTO.self)
    }

    private func performRequest<T: Decodable>(url: URL, as type: T.Type) async throws -> T {
        let (data, response) = try await client.get(url: url)
        guard (200 ... 299).contains(response.statusCode) else {
            throw WeatherAPIError.httpStatus(response.statusCode)
        }
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw WeatherAPIError.decodingFailed
        }
    }

    private func buildCurrentWeatherURL(for location: Location) throws -> URL {
        let trimmedName = location.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let queryValue = trimmedName.isEmpty
            ? "\(location.coordinate.latitude),\(location.coordinate.longitude)"
            : trimmedName
        return try buildCurrentWeatherURL(queryValue: queryValue)
    }

    private func buildCurrentWeatherURL(queryValue: String) throws -> URL {
        guard var components = URLComponents(url: config.baseURL, resolvingAgainstBaseURL: false) else {
            throw WeatherAPIError.invalidURL
        }

        components.queryItems = makeQueryItems(queryValue: queryValue, days: config.days)

        guard let url = components.url else {
            throw WeatherAPIError.invalidURL
        }
        return url
    }

    private func buildForecastURL(for location: String, days: Int) throws -> URL {
        guard var components = URLComponents(
            url: makeForecastBaseURL(from: config.baseURL),
            resolvingAgainstBaseURL: false
        ) else {
            throw WeatherAPIError.invalidURL
        }

        let safeLocation = String(location)
        components.queryItems = makeQueryItems(queryValue: safeLocation, days: days)

        guard let url = components.url else {
            throw WeatherAPIError.invalidURL
        }
        return url
    }

    private func makeQueryItems(queryValue: String, days: Int) -> [URLQueryItem] {
        var items: [URLQueryItem] = [
            URLQueryItem(name: "key", value: config.apiKey),
            URLQueryItem(name: "q", value: queryValue),
            URLQueryItem(name: "days", value: String(days)),
            URLQueryItem(name: "alerts", value: config.includeAlerts ? "yes" : "no"),
            URLQueryItem(name: "aqi", value: config.includeAQI ? "yes" : "no"),
        ]

        if let language = config.language {
            items.append(URLQueryItem(name: "lang", value: language))
        }
        return items
    }

    private func makeForecastBaseURL(from baseURL: URL) -> URL {
        let fallbackURL = URL(string: "https://api.weatherapi.com/v1/forecast.json")!
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            return fallbackURL
        }

        if components.path.hasSuffix("/current.json") {
            components.path = components.path.replacingOccurrences(of: "/current.json", with: "/forecast.json")
        } else if !components.path.hasSuffix("/forecast.json") {
            if components.path.isEmpty || components.path == "/" {
                components.path = "/v1/forecast.json"
            } else if components.path.hasSuffix("/") {
                components.path += "forecast.json"
            } else {
                components.path += "/forecast.json"
            }
        }

        components.query = nil
        components.queryItems = nil
        return components.url ?? fallbackURL
    }
}
