//
//  LoggerDataSource.swift
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

protocol LoggerDataSourceType {
    func add(log: LogType)
    var count: Int { get }
    func popAll() -> [LogType]
}

final class LoggerDatabase: LoggerDataSourceType {

    private let database: Database

    private struct Constants {
        static let tableName = "Log"
        static let columnId = "_id"
        static let columnLog = "log"
    }

    init(database: Database) {
        self.database = database
        createTableIfNotExists()
    }

    private func createTableIfNotExists() {
        let query = "CREATE TABLE IF NOT EXISTS " +
            "\(Constants.tableName) (" +
            "\(Constants.columnId) INTEGER PRIMARY KEY AUTOINCREMENT, " +
            "\(Constants.columnLog) BLOB NOT NULL" +
        ");"

        let statement = SQLStatement.Builder()
            .set(query: query)
            .build()

        do {
            _ = try database.execute(statement: statement)
        } catch let error {
            debugPrint(error.localizedDescription)
        }
    }
}

extension LoggerDatabase {

    func add(log: LogType) {
        let query = "INSERT INTO " +
            "\(Constants.tableName) " +
            "(\(Constants.columnLog)) " +
        "VALUES (?);"

        let statement = SQLStatement.Builder()
            .set(query: query)
            .set(args: [NSKeyedArchiver.archivedData(withRootObject: log)])
            .build()

        do {
            _ = try database.execute(statement: statement)
        } catch let error {
            debugPrint(error.localizedDescription)
        }
    }

    var count: Int {
        let query = "SELECT COUNT(*) FROM \(Constants.tableName)"

        let statement = SQLStatement.Builder()
            .set(query: query)
            .set(cached: true)
            .build()

        var count = -1
        do {
            let result = try database.execute(statement: statement)
            _ = result.next()
            count = Int(result.intValue(column: 0))

            return count
        } catch let error {
            debugPrint(error.localizedDescription)
            return count
        }
    }

    private func clear() {
        let query = "DELETE FROM \(Constants.tableName)"
        let statement = SQLStatement.Builder()
            .set(query: query)
            .build()

        do {
            _ = try database.execute(statement: statement)
        } catch let error {
            debugPrint(error.localizedDescription)
        }
    }

    func popAll() -> [LogType] {
        let query = "SELECT * FROM \(Constants.tableName)"
        let statement = SQLStatement.Builder()
            .set(query: query)
            .set(cached: true)
            .build()

        var logs = [LogType]()

        do {
            let result = try database.execute(statement: statement)

            while result.next() {
                let data = result.dataValue(column: Constants.columnLog)

                if let data = data,
                    let log = NSKeyedUnarchiver.unarchiveObject(with: data) as? LogType {
                    logs.append(log)
                }
            }

        } catch let error {
            debugPrint(error.localizedDescription)
        }

        clear()
        return logs
    }

}
