//
//  Log.swift
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

extension LogLevel {
    fileprivate var stringValue: String {
        let value: String

        switch self {
        case .error:
            value = "ERROR"
        case .warn:
            value = "WARN"
        case .info:
            value = "INFO"
        case .verbose:
            value = "VERBOSE"
        default:
            value = "NONE"
        }

        return value
    }
}

protocol LogType: NSCoding {
    var stringFormat: String { get }
}

final class Log: NSObject, LogType {

    private struct Keys {
        static let messageKey = "message"
        static let logLevelKey = "logLevel"
    }

    let message: String
    let logLevel: LogLevel

    private init(message: String, logLevel: LogLevel) {
        self.message = message
        self.logLevel = logLevel
    }

    init?(coder aDecoder: NSCoder) {
        let deccodedMessage = aDecoder.decodeObject(forKey: Keys.messageKey) as? String
        message = deccodedMessage!
        logLevel = LogLevel(rawValue: aDecoder.decodeInteger(forKey: Keys.logLevelKey))!
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(message, forKey: Keys.messageKey)
        aCoder.encode(logLevel.rawValue, forKey: Keys.logLevelKey)
    }

    var stringFormat: String {
        return "\(logLevel.stringValue) | \(message)"
    }
}

extension Log {

    class Builder {
        private var message = ""
        private var logLevel = LogLevel.none

        func set(message: String) -> Builder {
            self.message = message
            return self
        }

        func set(logLevel: LogLevel) -> Builder {
            self.logLevel = logLevel
            return self
        }

        func build() -> Log {
            return Log(message: message, logLevel: logLevel)
        }
    }
}

extension Log {
}
