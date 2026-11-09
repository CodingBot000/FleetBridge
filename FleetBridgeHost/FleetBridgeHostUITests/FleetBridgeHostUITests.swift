//
//  FleetBridgeHostUITests.swift
//  FleetBridgeHostUITests
//
//  Created by switch on 11/9/26.
//

import XCTest

final class FleetBridgeHostUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // XCUIAutomation Documentation
        // https://developer.apple.com/documentation/xcuiautomation
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    @MainActor
    func testVehicleDetailSwitchesBetweenSelections() {
        let app = XCUIApplication()
        app.launch()
        for iteration in 0..<20 {
            let index = iteration % 2 + 1
            let cell = app.cells["vehicle-\(index)"]
            XCTAssertTrue(cell.waitForExistence(timeout: 15))
            cell.tap()
            XCTAssertTrue(app.staticTexts["Fleet Model \(index)"].waitForExistence(timeout: 20))
            XCTAssertTrue(app.staticTexts["vehicle-\(index)"].exists)
            app.buttons["목록으로 돌아가기"].tap()
        }
        XCTAssertTrue(app.cells["vehicle-1"].waitForExistence(timeout: 10))
    }
}
