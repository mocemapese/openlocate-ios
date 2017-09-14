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

import Foundation
@testable import OpenLocate

class SuccessURLSessionDataTask: URLSessionDataTaskProtocol {
    private let completion: DataTaskResult
    private let request: URLRequest

    init(request: URLRequest, completionHandler: @escaping DataTaskResult) {
        self.completion = completionHandler
        self.request = request
    }

    func resume() {
        let data = "{}".data(using: .utf8)
        let urlResponse = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: "1.1",
            headerFields: request.allHTTPHeaderFields
        )
        completion(data, urlResponse, nil)
    }
}

class SuccessURLSession: URLSessionProtocol {

    func dataTask(with request: URLRequest,
                  completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProtocol {
        return SuccessURLSessionDataTask(request: request, completionHandler: completionHandler)
    }

}

class FailureURLSessionDataTask: URLSessionDataTaskProtocol {
    private let completion: DataTaskResult
    private let request: URLRequest

    init(request: URLRequest, completionHandler: @escaping DataTaskResult) {
        self.completion = completionHandler
        self.request = request
    }

    func resume() {
        let data = "{}".data(using: .utf8)
        let urlResponse = HTTPURLResponse(
            url: request.url!,
            statusCode: 400,
            httpVersion: "1.1",
            headerFields: request.allHTTPHeaderFields
        )
        completion(data, urlResponse, nil)
    }
}

class FailureURLSession: URLSessionProtocol {

    func dataTask(with request: URLRequest,
                  completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProtocol {
        return FailureURLSessionDataTask(request: request, completionHandler: completionHandler)
    }

}

class NonHttpURLSessionDataTask: URLSessionDataTaskProtocol {
    private let completion: DataTaskResult
    private let request: URLRequest

    init(request: URLRequest, completionHandler: @escaping DataTaskResult) {
        self.completion = completionHandler
        self.request = request
    }

    func resume() {
        let data = "{}".data(using: .utf8)
        let urlResponse = URLResponse(url: request.url!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        completion(data, urlResponse, nil)
    }
}

class NonHttpURLSession: URLSessionProtocol {

    func dataTask(with request: URLRequest,
                  completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProtocol {
        return NonHttpURLSessionDataTask(request: request, completionHandler: completionHandler)
    }

}
