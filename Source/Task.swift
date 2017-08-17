//
//  Task.swift
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

typealias TaskCallback = (Task) -> Void
typealias TaskID = Int

private var taskIdCounter: TaskID = 0

private func getNextTaskId() -> TaskID {
    taskIdCounter += 1
    return taskIdCounter
}

protocol Task {
    var taskId: Int { get }
    var callback: TaskCallback { get }
}

class PeriodicTask: Task {

    let interval: TimeInterval
    let callback: TaskCallback
    let taskId: TaskID

    private init(
        interval: TimeInterval,
        callback: @escaping TaskCallback) {
        self.interval = interval
        self.callback = callback
        self.taskId = getNextTaskId()
    }
}

extension PeriodicTask {

    final class Builder {
        private var interval: TimeInterval = 30.0
        private var callback: TaskCallback = { _ in }

        func set(interval: TimeInterval) -> Builder {
            self.interval = interval
            return self
        }

        func set(callback: @escaping TaskCallback) -> Builder {
            self.callback = callback
            return self
        }

        func build() -> PeriodicTask {
            return PeriodicTask(interval: interval, callback: callback)
        }
    }
}
