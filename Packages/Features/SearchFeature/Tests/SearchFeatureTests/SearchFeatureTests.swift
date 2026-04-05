import SearchFeatureAPI
import XCTest

final class SearchFeatureTests: XCTestCase {
    func testSearchReturnsResultsForMatchingQuery() async throws {
        let provider = SearchFeatureFactory.live()

        let results = try await provider.search(query: "del")

        XCTAssertEqual(results, [SearchLocation(name: "New Delhi")])
    }

    func testSearchThrowsErrorForSimulatedFailureQuery() async {
        let provider = SearchFeatureFactory.live()

        await XCTAssertThrowsErrorAsync {
            _ = try await provider.search(query: "error")
        }
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
