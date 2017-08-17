//
//  DataSourceTests.swift
//
//  Copyright (c) 2017 OpenLocate
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import XCTest
@testable import OpenLocate
import CoreLocation

class LocationDataSourceTests: BaseTestCase {
    private var dataSource: LocationDataSourceType?

    var testLocation: OpenLocateLocation {
        let coreLocation = CLLocation(latitude: 123.12, longitude: 123.123)
        let advertisingInfo = AdvertisingInfo.Builder()
            .set(isLimitedAdTrackingEnabled: false)
            .set(advertisingId: "123")
            .build()
        return OpenLocateLocation(
            location: coreLocation,
            advertisingInfo: advertisingInfo
        )
    }

    override func setUp() {
        do {
            let database = try SQLiteDatabase.testDB()
            dataSource = LocationDatabase(database: database)
            _ = dataSource!.popAll()
        } catch let error {
            debugPrint(error.localizedDescription)
        }
    }

    func testAddLocations() {
        // Given
        guard let locations = dataSource else {
            XCTFail("No database")
            return
        }

        // When
        do {
            try locations.add(location: testLocation)
        } catch let error {
            debugPrint(error.localizedDescription)
            XCTFail("Add Location error")
        }

        // Then
        XCTAssertEqual(locations.count, 1)
    }

    func testAddMultipleLocations() {
        // Given
        guard let locations = dataSource else {
            XCTFail("No database")
            return
        }

        // When
        let multiple = [testLocation, testLocation, testLocation]
        locations.addAll(locations: multiple)

        // Then
        XCTAssertEqual(locations.count, 3)
    }

    func testPopLocations() {
        // Given
        guard let locations = dataSource else {
            XCTFail("No database")
            return
        }

        // When
        let multiple = [testLocation, testLocation, testLocation, testLocation]
        locations.addAll(locations: multiple)
        let popped = locations.popAll()

        // Then
        XCTAssertEqual(popped.count, 4)
        XCTAssertEqual(locations.count, 0)
    }
}

class LocationListDataSource: BaseTestCase {
    private var dataSource: LocationDataSourceType?

    var testLocation: OpenLocateLocation {
        let coreLocation = CLLocation(latitude: 123.12, longitude: 123.123)
        let advertisingInfo = AdvertisingInfo.Builder()
            .set(isLimitedAdTrackingEnabled: false)
            .set(advertisingId: "123")
            .build()
        return OpenLocateLocation(
            location: coreLocation,
            advertisingInfo: advertisingInfo
        )
    }

    override func setUp() {
        dataSource = LocationList()
        _ = dataSource!.popAll()
    }

    func testAddLocations() {
        // Given
        guard let locations = dataSource else {
            XCTFail("No database")
            return
        }

        // When
        do {
            try locations.add(location: testLocation)
        } catch let error {
            debugPrint(error.localizedDescription)
            XCTFail("Add Location error")
        }

        // Then
        XCTAssertEqual(locations.count, 1)
    }

    func testAddMultipleLocations() {
        // Given
        guard let locations = dataSource else {
            XCTFail("No database")
            return
        }

        // When
        let multiple = [testLocation, testLocation, testLocation]
        locations.addAll(locations: multiple)

        // Then
        XCTAssertEqual(locations.count, 3)
    }

    func testPopLocations() {
        // Given
        guard let locations = dataSource else {
            XCTFail("No database")
            return
        }

        // When
        let multiple = [testLocation, testLocation, testLocation, testLocation]
        locations.addAll(locations: multiple)
        let popped = locations.popAll()

        // Then
        XCTAssertEqual(popped.count, 4)
        XCTAssertEqual(locations.count, 0)
    }
}
