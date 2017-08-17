//
//  Logger.swift
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

enum LogLevel: Int {
    case none = 0
    case error
    case warn
    case info
    case verbose
}

enum LoggerError: Error {
    case invalidLogLevel
}

protocol Logger {
    var logLevel: LogLevel { get }

    func error(_ message: String)
    func warn(_ message: String)
    func info(_ message: String)
    func verbose(_ message: String)

    func log(_ log: LogType)
}

extension Logger {

    func error(_ message: String) {
        try? log(message: message, logLevel: .error)
    }

    func warn(_ message: String) {
        try? log(message: message, logLevel: .warn)
    }

    func info(_ message: String) {
        try? log(message: message, logLevel: .info)
    }

    func verbose(_ message: String) {
        try? log(message: message, logLevel: .verbose)
    }

    private func log(message: String, logLevel: LogLevel) throws {
        guard shouldLog(logLevel: logLevel) else {
            throw LoggerError.invalidLogLevel
        }

        let logMessage = Log.Builder()
            .set(message: message)
            .set(logLevel: logLevel)
            .build()

        log(logMessage)
    }

    private func shouldLog(logLevel: LogLevel) -> Bool {
        return self.logLevel != .none && logLevel.rawValue <= self.logLevel.rawValue
    }
}

final class DatabaseLogger: Logger {

    let logLevel: LogLevel
    private let dataSource: LoggerDataSourceType

    init(dataSource: LoggerDataSourceType, logLevel: LogLevel) {
        self.dataSource = dataSource
        self.logLevel = logLevel
    }
}

extension DatabaseLogger {
    func log(_ log: LogType) {
        dataSource.add(log: log)
    }
}

final class ConsoleLogger: Logger {
    let logLevel: LogLevel

    init(logLevel: LogLevel) {
        self.logLevel = logLevel
    }

    func log(_ log: LogType) {
        print(log.stringFormat)
    }
}

final class RemoteLogger: Logger {
    let logLevel: LogLevel
    let writeable: Writeable

    init(writeable: Writeable, logLevel: LogLevel) {
        self.writeable = writeable
        self.logLevel = logLevel
    }

    func log(_ log: LogType) {
        try? writeable.write(data: log.stringFormat) { _, _ in }
    }
}
