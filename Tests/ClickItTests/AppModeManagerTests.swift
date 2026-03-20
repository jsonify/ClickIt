import XCTest
@testable import ClickIt

final class AppModeManagerTests: XCTestCase {

    private let testKey = "appMode"

    override func setUp() {
        super.setUp()
        // Clear persisted value before each test
        UserDefaults.standard.removeObject(forKey: testKey)
    }

    override func tearDown() {
        super.tearDown()
        UserDefaults.standard.removeObject(forKey: testKey)
    }

    func testDefaultModeIsLite() {
        // No value stored — should return .lite
        XCTAssertEqual(AppModeManager.current, .lite)
    }

    func testSaveAndReadProMode() {
        AppModeManager.current = .pro
        XCTAssertEqual(AppModeManager.current, .pro)
    }

    func testSaveAndReadLiteMode() {
        AppModeManager.current = .pro
        AppModeManager.current = .lite
        XCTAssertEqual(AppModeManager.current, .lite)
    }

    func testRoundTrip() {
        for mode in AppMode.allCases {
            AppModeManager.current = mode
            XCTAssertEqual(AppModeManager.current, mode, "Round-trip failed for mode: \(mode)")
        }
    }

    func testInvalidRawValueFallsBackToDefault() {
        // Manually write an invalid string to UserDefaults
        UserDefaults.standard.set("invalid_mode", forKey: testKey)
        XCTAssertEqual(AppModeManager.current, .lite)
    }
}
