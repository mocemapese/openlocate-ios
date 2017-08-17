//
//  Statement.swift
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

typealias StatementArgs = [Any]

protocol Statement {
    var args: StatementArgs { get }
    var cached: Bool { get }
    var statement: String { get }
}

struct SQLStatement: Statement {
    let query: String
    let args: StatementArgs
    let cached: Bool

    var statement: String {
        return String(format: query, args)
    }

    private init(query: String, args: StatementArgs, cached: Bool) {
        self.query = query
        self.args = args
        self.cached = cached
    }
}

extension SQLStatement {

    final class Builder {
        var query = ""
        var args = StatementArgs()
        var cached = false

        func set(query: String) -> Builder {
            self.query = query
            return self
        }

        func set(args: StatementArgs) -> Builder {
            self.args = args
            return self
        }

        func set(cached: Bool) -> Builder {
            self.cached = cached
            return self
        }

        func build() -> SQLStatement {
            return SQLStatement(query: query, args: args, cached: cached)
        }
    }
}
