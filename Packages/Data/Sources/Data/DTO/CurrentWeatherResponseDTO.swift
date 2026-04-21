//
//  CurrentWeatherResponseDTO.swift
//  Data
//
//  Created by Prashant Gautam on 10/04/26.
//

import Foundation

public struct CurrentWeatherResponseDTO: Decodable, Sendable {
    public let current: CurrentDTO

    public init(current: CurrentDTO) {
        self.current = current
    }
}

public struct CurrentDTO: Decodable, Sendable {
    public let tempC: Double
    public let condition: ConditionDTO

    public init(tempC: Double, condition: ConditionDTO) {
        self.tempC = tempC
        self.condition = condition
    }

    private enum CodingKeys: String, CodingKey {
        case tempC = "temp_c"
        case condition
    }
}

public struct ConditionDTO: Decodable, Sendable {
    public let text: String
    public let code: Int

    public init(text: String, code: Int) {
        self.text = text
        self.code = code
    }
}
