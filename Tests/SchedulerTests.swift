//
//  SchedulerTests.swift
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

class TaskSchedulerTests: BaseTestCase {

    func testTaskSchedulerScheduleTasks() {
        let scheduler = TaskScheduler()
        XCTAssertFalse(scheduler.scheduled)

        let task1 = PeriodicTask.Builder().build()

        scheduler.schedule(task: task1)
        XCTAssertTrue(scheduler.scheduled)

        let task2 = PeriodicTask.Builder().build()
        scheduler.schedule(task: task2)
        XCTAssertTrue(scheduler.scheduled)

        scheduler.cancel(task: task2)
        XCTAssertTrue(scheduler.scheduled)

        scheduler.cancel(task: task1)
        XCTAssertFalse(scheduler.scheduled)
    }

    func testCancelWithoutScheduling() {
        // Given
        let scheduler = TaskScheduler()
        let task1 = PeriodicTask.Builder().build()

        // When
        scheduler.cancel(task: task1)

        // Then
        XCTAssertFalse(scheduler.scheduled)
    }

    func testSchedulerTimer() {
        // Given
        let timeInterval: TimeInterval = 0.1
        let durationExpectation = expectation(description: "Scheduler callback expectation")
        let scheduler = TaskScheduler(timeInterval: timeInterval)
        let task = PeriodicTask.Builder().set(callback: { _ in
            durationExpectation.fulfill()
        }).build()

        // When
        scheduler.schedule(task: task)

        // Then
        waitForExpectations(timeout: timeInterval + 0.1, handler: nil)
    }
}
