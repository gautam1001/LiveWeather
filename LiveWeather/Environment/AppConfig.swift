//
//  AppConfig.swift
//  LiveWeather
//
//  Created by Prashant Gautam on 22/03/26.
//

import Foundation

enum AppConfig {
    static var weatherAPIKey: String {
        ConfigProvider.shared.value(for: .weatherApiKey)
    }

    static var weatherAPIUrl: String {
        ConfigProvider.shared.value(for: .weatherApiUrl)
    }
}

final class ConfigProvider {
    static let shared = ConfigProvider()

    private let dictionary: [String: Any]

    private init() {
        dictionary = Bundle.main.infoDictionary ?? [:]
    }

    func value<T>(for key: ConfigKeys) -> T {
        guard let value = dictionary[key.rawValue] as? T else {
            fatalError("Missing config value for \(key.rawValue)")
        }
        return value
    }
}

enum ConfigKeys: String {
    case weatherApiUrl = "WeatherApiUrl"
    case weatherApiKey = "WeatherApiKey"
    case appName = "CFBundleName"
    case bundleIdentifier = "CFBundleIdentifier"
    case appVersion = "CFBundleShortVersionString"
    case buildNumber = "CFBundleVersion"
}
