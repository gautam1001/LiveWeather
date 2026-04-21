import Foundation

public enum SearchFeatureServiceError: Error {
    case simulatedFailure
}

public struct LiveSearchFeatureService: Sendable {
    public init() {}

    public func search(query: String) throws -> [String] {
        let safeQuery = String(query).trimmingCharacters(in: .whitespacesAndNewlines)
        if safeQuery.lowercased() == "error" {
            throw SearchFeatureServiceError.simulatedFailure
        }

        if safeQuery.isEmpty {
            return []
        }

        return [safeQuery]
    }
}
