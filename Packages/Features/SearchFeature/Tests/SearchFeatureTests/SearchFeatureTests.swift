import SearchFeatureAPI
import SearchFeatureImpl
import XCTest

final class SearchFeatureTests: XCTestCase {
    func testSearchReturnsTypedLocationForAnyQuery() async throws {
        let provider = SearchFeatureFactory.live()

        let results = try await provider.search(query: "del")

        XCTAssertEqual(results, [SearchLocation(name: "del")])
    }

    func testSearchTrimsWhitespaceFromQuery() async throws {
        let provider = SearchFeatureFactory.live()

        let results = try await provider.search(query: "   New Delhi  ")

        XCTAssertEqual(results, [SearchLocation(name: "New Delhi")])
    }

    func testSearchThrowsErrorForSimulatedFailureQuery() async {
        let provider = SearchFeatureFactory.live()

        await XCTAssertThrowsErrorAsync {
            _ = try await provider.search(query: "error")
        }
    }

    func testSearchIsStableUnderConcurrentRequests() async throws {
        let provider = SearchFeatureFactory.live()
        let queries = [
            "new",
            "del",
            "mum",
            "ben",
            "noi",
            "gha",
        ]

        let results = try await withThrowingTaskGroup(of: [SearchLocation].self) { group in
            for query in queries {
                group.addTask {
                    try await provider.search(query: query)
                }
            }

            var collected: [[SearchLocation]] = []
            for try await value in group {
                collected.append(value)
            }
            return collected
        }

        XCTAssertEqual(results.count, queries.count)
        XCTAssertTrue(results.allSatisfy { $0.count == 1 })
    }
}

private func XCTAssertThrowsErrorAsync(
    _ expression: @escaping () async throws -> Void,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        try await expression()
        XCTFail("Expected error to be thrown", file: file, line: line)
    } catch {}
}
