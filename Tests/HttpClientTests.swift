//
//  HttpClientTests.swift
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

@testable import OpenLocate
import XCTest

class HttpClientTests: BaseTestCase {

    let validRequestParameters
        = URLRequestParamters(url: "http://www.google.com",
                              params: nil,
                              queryParams: nil,
                              additionalHeaders: nil)

    let invalidRequestParameters
        = URLRequestParamters(url: "\\",
                              params: nil,
                              queryParams: nil,
                              additionalHeaders: nil)

    let nonHttpParameters
        = URLRequestParamters(url: "/post/",
                              params: nil,
                              queryParams: nil,
                              additionalHeaders: nil)

    func testPostResult() {
        // Given
        let timeOut: TimeInterval = 0.1
        let client = HttpClient(urlSession: SuccessURLSession())
        let expect = expectation(description: "Post should return")

        // When
        try? client.post(
            parameters: validRequestParameters,
            success: { _, _ in
                XCTAssertTrue(true)
                expect.fulfill()
        },
            failure: { _, _ in
                XCTFail("Test for success post request cannot fail")
                expect.fulfill()
        }
        )

        waitForExpectations(timeout: timeOut, handler: nil)
    }

    func testFailurePostResult() {
        // Given
        let timeOut: TimeInterval = 0.1
        let client = HttpClient(urlSession: FailureURLSession())
        let expect = expectation(description: "Post should return")

        // When
        try? client.post(
            parameters: validRequestParameters,
            success: { _, _ in
                XCTFail("Test for failure post request cannot succed")
                expect.fulfill()
        },
            failure: { _, _ in
                XCTAssertTrue(true)
                expect.fulfill()
        }
        )

        waitForExpectations(timeout: timeOut, handler: nil)
    }

    func testInvalidPostUrl() {
        // Given
        let client = HttpClient(urlSession: FailureURLSession())

        // When
        XCTAssertThrowsError(
            try client.post(
                parameters: invalidRequestParameters,
                success: { _, _ in
                    XCTAssertTrue(true)
            },
                failure: { _, _ in
                    XCTAssertTrue(true)
            })
        )
    }

    func testNonHttpUrlResponse() {
        // Given
        let timeOut: TimeInterval = 0.1
        let client = HttpClient(urlSession: NonHttpURLSession())
        let expect = expectation(description: "Post should return")

        // When
        try? client.post(
            parameters: nonHttpParameters,
            success: { _, _ in
                XCTFail("Test of non http url response cannot succed")
                expect.fulfill()
        },
            failure: { _, _ in
                XCTAssertTrue(true)
                expect.fulfill()
        })

        waitForExpectations(timeout: timeOut, handler: nil)
    }

}
