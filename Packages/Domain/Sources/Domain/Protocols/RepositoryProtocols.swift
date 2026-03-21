//
//  File.swift
//  Domain
//
//  Created by Prashant Gautam on 21/03/26.
//

import Foundation

public protocol WeatherRepository: Sendable {
    func getCurrentWeather(for location: String) async throws -> WeatherNow
}
