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
        app.launchEnvironment["FLEETBRIDGE_UI_TEST"] = "1"
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
        app.launchEnvironment["FLEETBRIDGE_UI_TEST"] = "1"
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
    @MainActor
    func testInvalidVehicleShowsErrorAndReturnsToList() {
        let app = XCUIApplication()
        app.launchEnvironment["FLEETBRIDGE_UI_TEST"] = "1"
        app.launchArguments.append("-ui-test-invalid-vehicle")
        app.launch()
        let cell = app.cells["vehicle-1"]
        XCTAssertTrue(cell.waitForExistence(timeout: 15))
        cell.tap()
        XCTAssertTrue(app.staticTexts["차량 정보를 불러올 수 없습니다."].waitForExistence(timeout: 20), app.debugDescription)
        app.buttons["목록으로 돌아가기"].tap()
        XCTAssertTrue(cell.waitForExistence(timeout: 10))
    }
    @MainActor
    func testBackgroundAndReturnToDetail() {
        let app = XCUIApplication()
        app.launchEnvironment["FLEETBRIDGE_UI_TEST"] = "1"
        app.launch()
        let cell = app.cells["vehicle-1"]
        XCTAssertTrue(cell.waitForExistence(timeout: 15))
        cell.tap()
        XCTAssertTrue(app.staticTexts["vehicle-1"].waitForExistence(timeout: 20))
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.staticTexts["vehicle-1"].waitForExistence(timeout: 20))
        app.buttons["목록으로 돌아가기"].tap()
        XCTAssertTrue(cell.waitForExistence(timeout: 10))
    }
    @MainActor
    func testLateCommandAfterCloseDoesNotAffectNextDetail() {
        let app = XCUIApplication()
        app.launchEnvironment["FLEETBRIDGE_UI_TEST"] = "1"
        app.launch()
        let first = app.cells["vehicle-1"]
        XCTAssertTrue(first.waitForExistence(timeout: 15))
        first.tap()
        XCTAssertTrue(app.staticTexts["vehicle-1"].waitForExistence(timeout: 20))
        let scenario = app.buttons["성공 시나리오"]
        if !scenario.isHittable { app.swipeUp() }
        scenario.tap()
        app.buttons["시간 초과 시나리오"].tap()
        let command = app.buttons["냉동기 전환"]
        command.tap()
        XCTAssertTrue(app.buttons["처리 중…"].waitForExistence(timeout: 5))
        app.buttons["목록으로 돌아가기"].tap()
        let second = app.cells["vehicle-2"]
        XCTAssertTrue(second.waitForExistence(timeout: 15))
        second.tap()
        XCTAssertTrue(app.staticTexts["vehicle-2"].waitForExistence(timeout: 20))
        XCTAssertFalse(app.staticTexts["응답 시간 초과"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["vehicle-2"].exists)
        app.buttons["목록으로 돌아가기"].tap()
    }
    @MainActor
    func testThirtyFirstFrames() {
        let app = XCUIApplication()
        app.launchEnvironment["FLEETBRIDGE_UI_TEST"] = "1"
        app.launchEnvironment["FLEETBRIDGE_MEASURE"] = "1"
        app.launch()
        for index in 0..<30 {
            let cell = app.cells["vehicle-\(index % 2 + 1)"]
            XCTAssertTrue(cell.waitForExistence(timeout: 15))
            cell.tap()
            let metric = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "FLEET_FRAME_MS=")).firstMatch
            XCTAssertTrue(metric.waitForExistence(timeout: 20))
            print("FLEET_MEASUREMENT \(index) \(metric.label)")
            app.buttons["목록으로 돌아가기"].tap()
        }
    }
}
