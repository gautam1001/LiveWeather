//
//  ForecastResponseDTO.swift
//  Data
//
//  Created by Prashant Gautam on 21/03/26.
//

import Foundation

public struct ForecastResponseDTO: Decodable, Sendable {
    public let current: CurrentDTO
}

public struct CurrentDTO: Decodable, Sendable {
    public let temp_c: Double
    public let condition: ConditionDTO
}

public struct ConditionDTO: Decodable, Sendable {
    public let text: String
    public let code: Int
}
