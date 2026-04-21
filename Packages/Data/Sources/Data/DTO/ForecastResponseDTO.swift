//
//  ForecastResponseDTO.swift
//  Data
//
//  Created by Prashant Gautam on 21/03/26.
//

import Foundation

public struct ForecastResponseDTO: Decodable, Sendable {
    public let forecast: ForecastDTO

    public init(forecast: ForecastDTO) {
        self.forecast = forecast
    }
}

public struct ForecastDTO: Decodable, Sendable {
    public let forecastDay: [ForecastDayDTO]

    public init(forecastDay: [ForecastDayDTO]) {
        self.forecastDay = forecastDay
    }

    private enum CodingKeys: String, CodingKey {
        case forecastDay = "forecastday"
    }
}

public struct ForecastDayDTO: Decodable, Sendable {
    public let date: String
    public let day: DayDTO

    public init(date: String, day: DayDTO) {
        self.date = date
        self.day = day
    }
}

public struct DayDTO: Decodable, Sendable {
    public let avgTempC: Double
    public let minTempC: Double
    public let maxTempC: Double
    public let condition: ConditionDTO

    public init(avgTempC: Double, minTempC: Double, maxTempC: Double, condition: ConditionDTO) {
        self.avgTempC = avgTempC
        self.minTempC = minTempC
        self.maxTempC = maxTempC
        self.condition = condition
    }

    private enum CodingKeys: String, CodingKey {
        case avgTempC = "avgtemp_c"
        case minTempC = "mintemp_c"
        case maxTempC = "maxtemp_c"
        case condition
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        minTempC = try container.decode(Double.self, forKey: .minTempC)
        maxTempC = try container.decode(Double.self, forKey: .maxTempC)
        condition = try container.decode(ConditionDTO.self, forKey: .condition)
        let decodedAverage = try container.decodeIfPresent(Double.self, forKey: .avgTempC)
        avgTempC = decodedAverage ?? ((minTempC + maxTempC) / 2)
    }
}
