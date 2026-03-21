//
//  WeatherAPIMapper.swift
//  Data
//
//  Created by Prashant Gautam on 21/03/26.
//

import Foundation
import Domain

public struct WeatherAPIMapper: Sendable {
    public init() {}
    
    public func mapCurrent(_ dto: ForecastResponseDTO) throws -> WeatherNow {
        WeatherNow(
            temperatureC: dto.current.temp_c,
            conditionCode: dto.current.condition.code,
            conditionSummary: dto.current.condition.text,
            conditionDescription: dto.current.condition.text
        )
    }
}
