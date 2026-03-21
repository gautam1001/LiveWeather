//
//  File.swift
//  Domain
//
//  Created by Prashant Gautam on 21/03/26.
//

import Foundation

public struct WeatherNow: Equatable, Sendable {
    public let temperatureC: Double
    public let conditionCode: Int
    public let conditionSummary: String
    public let conditionDescription: String

    public init(
        temperatureC: Double,
        conditionCode: Int,
        conditionSummary: String,
        conditionDescription: String
    ) {
        self.temperatureC = temperatureC
        self.conditionCode = conditionCode
        self.conditionSummary = conditionSummary
        self.conditionDescription = conditionDescription
    }
}
