import Foundation

public enum SearchFeatureServiceError: Error {
    case simulatedFailure
}

public final class LiveSearchFeatureService {
    private let supportedLocations = [
        "New Delhi",
        "Noida",
        "Ghaziabad",
        "Bengaluru",
        "Mumbai",
    ]

    public init() {}

    public func search(query: String) async throws -> [String] {
        if query.lowercased() == "error" {
            throw SearchFeatureServiceError.simulatedFailure
        }

        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return []
        }

        return supportedLocations.filter { location in
            location.localizedCaseInsensitiveContains(query)
        }
    }
}
