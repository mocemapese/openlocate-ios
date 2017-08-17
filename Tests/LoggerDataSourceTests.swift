//
//  LoggerTests.swift
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

class LoggerDatabaseTests: BaseTestCase {

    private var dataSource: LoggerDataSourceType?

    private var logMessage: LogType {
        return Log.Builder()
            .set(logLevel: .warn)
            .set(message: "Test Message")
            .build()
    }

    override func setUp() {
        do {
            let database = try SQLiteDatabase.testDB()
            dataSource = LoggerDatabase(database: database)
            _ = dataSource!.popAll()
        } catch let error {
            debugPrint(error.localizedDescription)
        }
    }

    func testAddLog() {
        // Given
        guard let logs = dataSource else {
            XCTFail("No database")
            return
        }

        // When
        logs.add(log: logMessage)

        // Then
        XCTAssertEqual(logs.count, 1)
    }

    func testPopLogs() {
        // Given
        guard let logs = dataSource else {
            XCTFail("No database")
            return
        }

        // When
        logs.add(log: logMessage)
        logs.add(log: logMessage)
        let popped = logs.popAll()

        // Then
        XCTAssertEqual(popped.count, 2)
        XCTAssertEqual(logs.count, 0)
    }
}
