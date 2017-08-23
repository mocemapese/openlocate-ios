//
//  Scheduler.swift
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

protocol Scheduler {
    var timeInterval: TimeInterval { get set }

    func schedule(task: Task)
    func cancel(task: Task)
    var scheduled: Bool { get }
}

final class TaskScheduler: Scheduler {

    var timeInterval: TimeInterval {
        didSet {
            stopTimer()
            startTimerIfNeeded()
        }
    }
    private var tasks = [Task]()
    private var timer: Timer?

    init(timeInterval: TimeInterval) {
        self.timeInterval = timeInterval
    }

    func schedule(task: Task) {
        tasks.append(task)

        if tasks.count > 0 {
            startTimerIfNeeded()
        }
    }

    func cancel(task: Task) {
        tasks = tasks.filter { evaluatedTask in
            return task.taskId != evaluatedTask.taskId
        }

        if tasks.count == 0 {
            stopTimer()
        }
    }

    var scheduled: Bool {
        return timer != nil
    }
}

extension TaskScheduler {
    private func startTimerIfNeeded() {
        if timer != nil {
            return
        }

        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { _ in
            self.tasks.forEach { task in
                task.callback(task)
            }
        }
    }

    private func stopTimer() {
        if timer == nil {
            return
        }

        timer!.invalidate()
        timer = nil
    }
}
