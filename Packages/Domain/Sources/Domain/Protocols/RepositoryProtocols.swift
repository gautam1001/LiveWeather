//
//  RepositoryProtocols.swift
//  Domain
//
//  Created by Prashant Gautam on 21/03/26.
//

import Foundation

public protocol WeatherRepository: Sendable {
    func getCurrentWeather(for location: Location) async throws -> WeatherNow
}
