//
//  LocationManager.swift
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

typealias LocationsHandler = ([CLLocation]) -> Void

// Location Manager

protocol LocationManagerType {
    func subscribe(_ locationHandler: @escaping LocationsHandler)
    func cancel()

    var updatingLocation: Bool { get }
    var lastLocation: CLLocation? { get }
}

final class LocationManager: NSObject, LocationManagerType, CLLocationManagerDelegate {

    private let manager: CLLocationManager
    private var requests: [LocationsHandler] = []

    required init(manager: CLLocationManager = CLLocationManager()) {
        self.manager = manager
        super.init()
        manager.delegate = self
    }
    
    static func authorizationStatus() -> CLAuthorizationStatus {
        return CLLocationManager.authorizationStatus()
    }
    
    static func locationServicesEnabled() -> Bool {
        return CLLocationManager.locationServicesEnabled()
    }
    
    // MARK: CLLocationManager
    
    func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        
        var date = Date()
        if visit.departureDate != Date.distantFuture {
            date = visit.departureDate
        } else if visit.arrivalDate != Date.distantPast {
            date = visit.arrivalDate
        }
        
        let location = CLLocation(coordinate: visit.coordinate,
                                  altitude: 0,
                                  horizontalAccuracy: visit.horizontalAccuracy,
                                  verticalAccuracy: -1.0,
                                  timestamp: date)

        var locations = [location]
        if let currentLocation = manager.location {
            locations.append(currentLocation)
        }
        
        for request in requests {
            request(locations)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for request in requests {
            request(locations)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        debugPrint(error)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways && updatingLocation {
            manager.startMonitoringVisits()
            manager.startMonitoringSignificantLocationChanges()
        }
    }
    
    // MARK: LocationManagerType
    
    func subscribe(_ locationHandler: @escaping LocationsHandler) {
        requests.append(locationHandler)
        requestAuthorizationIfNeeded()
        manager.startMonitoringVisits()
        manager.startMonitoringSignificantLocationChanges()
    }
    
    func cancel() {
        requests.removeAll()
        manager.stopMonitoringVisits()
        manager.stopMonitoringSignificantLocationChanges()
    }
    
    var updatingLocation: Bool {
        return !requests.isEmpty
    }
    
    // MARK: Private
    
    private func requestAuthorizationIfNeeded() {
        let status = CLLocationManager.authorizationStatus()
        if status == .notDetermined || status == .authorizedWhenInUse {
            manager.requestAlwaysAuthorization()
        }
    }

    var lastLocation: CLLocation? {
        return manager.location
    }
}
