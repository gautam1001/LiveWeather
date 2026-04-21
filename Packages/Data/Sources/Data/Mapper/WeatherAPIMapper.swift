//
//  WeatherAPIMapper.swift
//  Data
//
//  Created by Prashant Gautam on 21/03/26.
//

import Domain
import Foundation

public struct WeatherAPIMapper: Sendable {
    public init() {}

    public func mapCurrent(_ dto: CurrentWeatherResponseDTO) throws -> WeatherNow {
        WeatherNow(
            temperatureC: dto.current.tempC,
            conditionCode: dto.current.condition.code,
            conditionSummary: dto.current.condition.text,
            conditionDescription: dto.current.condition.text
        )
    }
}
