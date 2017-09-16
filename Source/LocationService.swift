//
//  LocationService.swift
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
import CoreLocation

protocol LocationServiceType {
    func start()
    func stop()
}

private let locationsKey = "locations"

final class LocationService: LocationServiceType {

    private let locationManager: LocationManagerType
    private let httpClient: Postable
    private let locationDataSource: LocationDataSourceType
    private var scheduler: Scheduler
    private var advertisingInfo: AdvertisingInfo

    private var url: String
    private var headers: Headers?

    private var locationTask: Task?
    private var logTask: Task?

    init(
        postable: Postable,
        locationDataSource: LocationDataSourceType,
        scheduler: Scheduler,
        url: String,
        headers: Headers?,
        advertisingInfo: AdvertisingInfo,
        locationManager: LocationManagerType) {

        httpClient = postable
        self.locationDataSource = locationDataSource
        self.locationManager = locationManager
        self.scheduler = scheduler
        self.advertisingInfo = advertisingInfo
        self.url = url
        self.headers = headers
    }

    func start() {
        debugPrint("Location service started for url : \(url)")
        //schedule()

        locationManager.subscribe { locations in
            
            let openLocateLocations = locations.map {
                return OpenLocateLocation(location: $0, advertisingInfo: self.advertisingInfo)
            }
            
            self.locationDataSource.addAll(locations: openLocateLocations)
            
            debugPrint(self.locationDataSource.count)
        }
    }

    func stop() {
        unschedule()
        locationManager.cancel()
    }
}

extension LocationService {
    private func schedule() {
        scheduleLocationDispatch()
    }

    private func scheduleLocationDispatch() {
        locationTask = PeriodicTask.Builder()
            .set { _ in
                let indexedLocations = self.locationDataSource.popAll()
                let locations = indexedLocations.map { $1 }
                self.postLocations(locations: locations)
            }
            .build()
        scheduler.schedule(task: locationTask!)
    }

    private func unschedule() {
        if let task = locationTask {
            scheduler.cancel(task: task)
        }
    }

    private func postLocations(locations: [OpenLocateLocationType]) {
        if locations.isEmpty {
            return
        }

        let params = [locationsKey: locations.map { $0.json }]
        do {
            try httpClient.post(
                params: params,
                queryParams: nil,
                url: url,
                additionalHeaders: headers,
                success: { _, _ in
            }
            ) { _, _ in
                self.locationDataSource.addAll(locations: locations)
                print("failure in posting locations!!!")
            }
        } catch let error {
            print(error.localizedDescription)
        }
    }
}

extension LocationService {
    static func isEnabled() -> Bool {
        return LocationManager.locationServicesEnabled()
    }

    static func isAuthorizationDenied() -> Bool {
        return LocationManager.isAuthorizationDenied()
    }

    static func isAuthorizationKeysValid() -> Bool {
        let always = Bundle.main.object(forInfoDictionaryKey: "NSLocationAlwaysUsageDescription")
        let inUse = Bundle.main.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription")
        let alwaysAndinUse = Bundle.main.object(forInfoDictionaryKey: "NSLocationAlwaysAndWhenInUseUsageDescription")
        return always != nil || inUse != nil || alwaysAndinUse != nil
    }
}

extension LocationManager {
    static func isAuthorizationDenied() -> Bool {
        let authorizationStatus = LocationManager.authorizationStatus()
        return authorizationStatus == .denied || authorizationStatus == .restricted
    }
}
