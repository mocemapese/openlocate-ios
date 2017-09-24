//
//  HttpRequestTests.swift
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

class HttpRequestTests: BaseTestCase {

    func testDefaultRequestBuiler() {
        // Given
        let request = HttpRequest.Builder()
        .build()

        // Then
        XCTAssertEqual(request.url, "")
        XCTAssertTrue(request.url.isEmpty)
        XCTAssertEqual(request.method, .post)
    }

    func testRequestBuilder() {
        // Given
        let request = HttpRequest.Builder()
            .set(url: "/test/url/")
            .set(method: .post)
            .set(params: ["ABC": 123])
            .set(additionalHeaders: ["header": "value"])
            .set(failure: { _, _ in

            })
            .set(success: { _, _ in

            })
            .build()

        // Then
        XCTAssertEqual(request.url, "/test/url/")
        XCTAssertFalse(request.url.isEmpty)
        XCTAssertEqual(request.method, .post)
        XCTAssertEqual((request.params as? Dictionary)!, ["ABC": 123])
        XCTAssertEqual(request.additionalHeaders!, ["header": "value"])
    }

}

class URLRequestTests: BaseTestCase {

    func testURLReuquestInitializer() {
        // Given
        let request = HttpRequest.Builder()
            .set(url: "http://localhost/test/url/")
            .set(method: .post)
            .set(params: ["ABC": 123])
            .set(additionalHeaders: ["header": "value"])
            .set(failure: { _, _ in

            })
            .set(success: { _, _ in

            })
            .build()

        // When
        guard let urlRequest = URLRequest(request) else {
            XCTFail("urlRequest cannot be nil")

            return
        }

        // Then
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "header"), "value")
        XCTAssertEqual(urlRequest.url!, URL(string: "http://localhost/test/url/")!)
        XCTAssertEqual(urlRequest.httpMethod!, "POST")
    }
}
