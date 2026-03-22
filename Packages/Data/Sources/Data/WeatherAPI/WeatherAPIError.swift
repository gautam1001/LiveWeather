import Foundation

public enum WeatherAPIError: Error, Equatable {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case decodingFailed
    case emptyPayload
}
