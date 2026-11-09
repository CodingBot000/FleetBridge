//
//  FleetBridgeHostTests.swift
//  FleetBridgeHostTests
//
//  Created by switch on 11/9/26.
//

import XCTest
@testable import FleetBridgeHost

final class FleetBridgeHostTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
        // XCTest Documentation
        // https://developer.apple.com/documentation/xctest
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

final class VehicleRepositoryTests: XCTestCase {
    func testMockVehiclesHaveUniqueIDsAndCanBeLookedUp() {
        let repository = VehicleRepository()
        XCTAssertEqual(repository.vehicles.count, 10)
        XCTAssertEqual(Set(repository.vehicles.map(\.id)).count, 10)
        for vehicle in repository.vehicles {
            XCTAssertEqual(repository.vehicle(id: vehicle.id), vehicle)
        }
        XCTAssertNil(repository.vehicle(id: "missing"))
    }
}

final class VehicleSimulationTests: XCTestCase {
    func testAdvanceMovesDrivingAndLeavesOfflineUnchanged() {
        let repository = VehicleRepository()
        let before = repository.vehicles
        let now = Date(timeIntervalSince1970: 123456)
        repository.advance(now: now)
        XCTAssertGreaterThan(repository.vehicles[0].latitude, before[0].latitude)
        XCTAssertEqual(repository.vehicles[0].updatedAt, now)
        XCTAssertEqual(repository.vehicles[2], before[2])
        XCTAssertEqual(repository.vehicles[1].revision, before[1].revision + 1)
        for _ in 0..<5 { repository.advance(now: now) }
        XCTAssertEqual(repository.vehicles[0].status, "idle")
        XCTAssertEqual(repository.vehicles[1].status, "driving")
    }
}

extension VehicleSimulationTests {
    func testCommandSuccessAndDuplicateAreHandled() {
        let repository = VehicleRepository()
        let finished = expectation(description: "success")
        repository.setRefrigeration(id: "vehicle-1", enabled: true, scenario: "success") { outcome in
            XCTAssertEqual(outcome, "success")
            XCTAssertEqual(repository.vehicle(id: "vehicle-1")?.refrigerationOn, true)
            finished.fulfill()
        }
        repository.setRefrigeration(id: "vehicle-1", enabled: true, scenario: "success") { outcome in
            XCTAssertEqual(outcome, "busy")
        }
        wait(for: [finished], timeout: 5)
    }
    func testCommandFailureAndTimeout() {
        let repository = VehicleRepository()
        let failed = expectation(description: "failure")
        let timedOut = expectation(description: "timeout")
        repository.setRefrigeration(id: "vehicle-1", enabled: true, scenario: "failure") { outcome in
            XCTAssertEqual(outcome, "failure"); failed.fulfill()
        }
        repository.setRefrigeration(id: "vehicle-2", enabled: true, scenario: "timeout") { outcome in
            XCTAssertEqual(outcome, "timeout"); timedOut.fulfill()
        }
        wait(for: [failed, timedOut], timeout: 6)
        XCTAssertEqual(repository.vehicle(id: "vehicle-1")?.refrigerationOn, false)
    }
}
