import Foundation

struct FixtureLoader {
    static func loadData(named name: String, fileExtension: String = "json") throws -> Data {
        guard let url = Bundle.module.url(forResource: name, withExtension: fileExtension) else {
            throw FixtureError.notFound(name)
        }
        return try Data(contentsOf: url)
    }
}

enum FixtureError: Error, CustomStringConvertible {
    case notFound(String)

    var description: String {
        switch self {
        case .notFound(let name):
            return "Fixture not found: \(name)"
        }
    }
}
