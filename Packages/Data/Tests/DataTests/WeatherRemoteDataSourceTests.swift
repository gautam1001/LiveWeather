//
//  WeatherRemoteDataSourceTests.swift
//  Data
//
//  Created by Prashant Gautam on 23/03/26.
//

@testable import Data
@testable import Domain
import XCTest

final class WeatherRemoteDataSourceTests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDataSourceSuccess() async throws {
        let baseUrlString = "https://api.weatherapi.com/v1/forecast.json"
        let config = WeatherAPIConfig.weatherAPIDefault(apiKey: "12345", apiUrl: baseUrlString)
        let weatherData = try FixtureLoader.loadData(named: "weatherapi_sample")
        let httpResponse = HTTPURLResponse(url: config.baseURL, statusCode: 200, httpVersion: nil, headerFields: nil)
        let response = try XCTUnwrap(httpResponse)
        let client = URLSessionHTTPClientMock(data: weatherData, response: response)
        let datasource = WeatherAPIRemoteDataSource(client: client, config: config)
        let location = Location(name: "Pune", coordinate: Coordinate(latitude: 18.5204, longitude: 73.8567))
        let dto = try await datasource.fetchWeather(for: location)
        XCTAssertEqual(dto.current.tempC, 28.5)
    }

    func testDataSourceFailure() async throws {
        let baseUrlString = "https://api.weatherapi.com/v1/forecast.json"
        let config = WeatherAPIConfig.weatherAPIDefault(apiKey: "12345", apiUrl: baseUrlString)
        let weatherData = try FixtureLoader.loadData(named: "weatherapi_sample")

        let httpResponse = HTTPURLResponse(url: config.baseURL, statusCode: 200, httpVersion: nil, headerFields: nil)
        let response = try XCTUnwrap(httpResponse)
        let client = URLSessionHTTPClientMock(data: weatherData, response: response)
        let datasource = WeatherAPIRemoteDataSource(client: client, config: config)
        let location = Location(name: "Pune", coordinate: Coordinate(latitude: 18.5204, longitude: 73.8567))
        do {
            _ = try await datasource.fetchWeather(for: location)
        } catch {
            XCTAssertNotNil(error)
            if let weatherAPIError = error as? WeatherAPIError {
                XCTAssertEqual(weatherAPIError, WeatherAPIError.httpStatus(400))
            }
        }
    }

    func testDataSourceInValidDataFailure() async throws {
        let baseUrlString = "https://api.weatherapi.com/v1/forecast.json"
        let config = WeatherAPIConfig.weatherAPIDefault(apiKey: "12345", apiUrl: baseUrlString)

        let httpResponse = HTTPURLResponse(url: config.baseURL, statusCode: 200, httpVersion: nil, headerFields: nil)
        let response = try XCTUnwrap(httpResponse)
        let client = URLSessionHTTPClientMock(data: Data(), response: response)
        let datasource = WeatherAPIRemoteDataSource(client: client, config: config)
        let location = Location(name: "Pune", coordinate: Coordinate(latitude: 18.5204, longitude: 73.8567))
        do {
            _ = try await datasource.fetchWeather(for: location)
        } catch {
            XCTAssertNotNil(error)
            if let weatherAPIError = error as? WeatherAPIError {
                XCTAssertEqual(weatherAPIError, WeatherAPIError.decodingFailed)
            }
        }
    }

    func testDataSourceInValidResponseFailure() async throws {
        let baseUrlString = "https://api.weatherapi.com/v1/forecast.json"
        let config = WeatherAPIConfig.weatherAPIDefault(apiKey: "12345", apiUrl: baseUrlString)
        let client = URLSessionHTTPClientMock(data: Data(), response: nil)
        let datasource = WeatherAPIRemoteDataSource(client: client, config: config)
        let location = Location(name: "Pune", coordinate: Coordinate(latitude: 18.5204, longitude: 73.8567))
        do {
            _ = try await datasource.fetchWeather(for: location)
        } catch {
            XCTAssertNotNil(error)
            if let weatherAPIError = error as? WeatherAPIError {
                XCTAssertEqual(weatherAPIError, WeatherAPIError.invalidResponse)
            }
        }
    }
}

final class URLSessionHTTPClientMock: HTTPClient {
    private let data: Data
    private let response: HTTPURLResponse?

    init(data: Data, response: HTTPURLResponse?) {
        self.data = data
        self.response = response
    }

    func get(url _: URL) async throws -> (Data, HTTPURLResponse) {
        guard let httpResponse = response else {
            throw WeatherAPIError.invalidResponse
        }
        return (data, httpResponse)
    }
}
