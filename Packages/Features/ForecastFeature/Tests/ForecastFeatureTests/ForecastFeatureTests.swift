import ForecastFeatureAPI
import XCTest

final class ForecastFeatureTests: XCTestCase {
    func testFetchForecastReturnsRequestedNumberOfDays() async throws {
        let provider = ForecastFeatureFactory.live()

        let result = try await provider.fetchForecast(location: "New Delhi", days: 3)

        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result.first?.dateLabel, "Day 1")
    }

    func testFetchForecastThrowsErrorForInvalidInput() async {
        let provider = ForecastFeatureFactory.live()

        await XCTAssertThrowsErrorAsync {
            _ = try await provider.fetchForecast(location: "", days: 0)
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
