//
//  HttpResponse.swift
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

extension Int {
    var isSuccess: Bool {
        return self >= ResponseCode.codeOk && self < ResponseCode.redirect
    }
}

private struct ResponseCode {
    static let codeOk = 200
    static let redirect = 300
    static let badRequest = 400
}

struct HttpResponse {
    let statusCode: Int
    let body: ResponseBody?
    let error: Error?

    private init(statusCode: Int, body: ResponseBody?, error: Error?) {
        self.statusCode = statusCode
        self.body = body
        self.error = error
    }

    var success: Bool {
        return statusCode.isSuccess
    }
}

extension HttpResponse {

    final class Builder {
        private var statusCode = ResponseCode.codeOk
        private var body: ResponseBody?
        private var error: Error?

        func set(statusCode: Int) -> Builder {
            self.statusCode = statusCode
            return self
        }

        func set(body: ResponseBody?) -> Builder {
            self.body = body
            return self
        }

        func set(error: Error?) -> Builder {
            self.error = error
            return self
        }

        func build() -> HttpResponse {
            return HttpResponse(statusCode: statusCode, body: body, error: error)
        }
    }
}
