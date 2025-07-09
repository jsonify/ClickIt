import XCTest
@testable import ClickIt

final class ClickItTests: XCTestCase {
    
    func testAppConstants() {
        // Test that app constants are properly defined
        XCTAssertEqual(AppConstants.defaultWindowWidth, 300)
        XCTAssertEqual(AppConstants.defaultWindowHeight, 200)
        XCTAssertEqual(AppConstants.minimumOSVersion, "macOS 15.0")
        XCTAssertFalse(AppConstants.requiredFrameworks.isEmpty)
        XCTAssertFalse(AppConstants.requiredPermissions.isEmpty)
    }
    
    func testFrameworkConstants() {
        // Test framework-specific constants
        XCTAssertEqual(FrameworkConstants.CarbonConfig.escKeyCode, 53)
        XCTAssertEqual(FrameworkConstants.CoreGraphicsConfig.clickEventType, CGEventType.leftMouseDown)
    }
}