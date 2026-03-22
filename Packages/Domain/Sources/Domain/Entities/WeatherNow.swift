//
//  File.swift
//  Domain
//
//  Created by Prashant Gautam on 21/03/26.
//

import Foundation
public struct Coordinate: Equatable, Hashable, Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public struct Location: Equatable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let coordinate: Coordinate

    public init(id: UUID = UUID(), name: String, coordinate: Coordinate) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
    }
}

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
