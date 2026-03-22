//
//  AppConfig.swift
//  LiveWeather
//
//  Created by Prashant Gautam on 22/03/26.
//

import Foundation

enum AppConfig {
    static var weatherAPIKey: String {
        let key = Bundle.main.object(forInfoDictionaryKey: "WeatherApiKey") as? String
        return key?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
