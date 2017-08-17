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

class DatabaseLoggerTests: BaseTestCase {

    private var logger: Logger?
    private var dataSource: LoggerDataSourceType?

    override func setUp() {
        super.setUp()
        do {
            let database = try SQLiteDatabase.testDB()
            dataSource = LoggerDatabase(database: database)
            logger = DatabaseLogger(dataSource: dataSource!, logLevel: .warn)
            _ = dataSource!.popAll()
        } catch let error {
            debugPrint(error.localizedDescription)
        }
    }

    func testWarnLog() {
        guard let logger = logger,
            let logs = dataSource else {
            XCTFail("No database")
            return
        }

        // Given
        let message = "This is a test warning"

        // When
        logger.warn(message)

        // Then
        XCTAssertEqual(logs.count, 1)
    }

    func testInfoLog() {
        guard let logger = logger,
            let logs = dataSource else {
                XCTFail("No database")
                return
        }

        // Given
        let message = "This is a test info"

        // When
        logger.info(message)

        // Then
        XCTAssertEqual(logs.count, 0)
    }

    func testErrorLog() {
        guard let logger = logger,
            let logs = dataSource else {
                XCTFail("No database")
                return
        }

        // Given
        let message = "This is a test error"

        // When
        logger.error(message)

        // Then
        XCTAssertEqual(logs.count, 1)
    }

    func testVerboseLog() {
        guard let logger = logger,
            let logs = dataSource else {
                XCTFail("No database")
                return
        }

        // Given
        let message = "This is a test verbose"

        // When
        logger.verbose(message)

        // Then
        XCTAssertEqual(logs.count, 0)
    }
}

class ConsoleLoggerTests: BaseTestCase {
    private let logger = ConsoleLogger(logLevel: .info)

    func testInfoLog() {
        logger.info("Test")
        XCTAssertTrue(true)
    }
}

class WriteableClient: Writeable {
    func write(data: String, completion: @escaping TcpClientCompletionHandler) throws {
        let request = TcpRequest.Builder().build()
        let response = TcpResponse.Builder().build()
        completion(request, response)
    }
}

class RemoteLoggerTests: BaseTestCase {
    private let logger = RemoteLogger(writeable: WriteableClient(), logLevel: .info)

    func testInfoLog() {
        logger.info("Test")
        XCTAssertTrue(true)
    }
}
