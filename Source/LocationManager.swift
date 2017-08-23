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

typealias LocationHandler = (CLLocation) -> Void

// LocationManagerProtocol

protocol CLLocationManagerProtocol {
    var delegate: CLLocationManagerDelegate? { get set }
    var activityType: CLActivityType { get set }
    var desiredAccuracy: CLLocationAccuracy { get set }
    var pausesLocationUpdatesAutomatically: Bool { get set }
    var allowsBackgroundLocationUpdates: Bool { get set }

    func requestAlwaysAuthorization()
    func startUpdatingLocation()
    func stopUpdatingLocation()

    static func authorizationStatus() -> CLAuthorizationStatus
    static func locationServicesEnabled() -> Bool
}

extension CLLocationManager: CLLocationManagerProtocol { }

// Location Manager

protocol LocationManagerType {
    func subscribe(_ locationHandler: @escaping LocationHandler)
    func cancel()
    func set(accuracy: LocationAccuracy)

    var updatingLocation: Bool { get }

    static func authorizationStatus(_ locationManagerProtocol: CLLocationManagerProtocol.Type) -> CLAuthorizationStatus
    static func locationServicesEnabled(_ locationManagerProtocol: CLLocationManagerProtocol.Type) -> Bool
}

final class LocationManager: NSObject, LocationManagerType {

    private var manager: CLLocationManagerProtocol
    private var requests: [LocationHandler] = []

    required init(manager: CLLocationManagerProtocol = CLLocationManager()) {
        self.manager = manager
        super.init()
        configure()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    private func configure() {
        manager.delegate = self

        manager.activityType = .automotiveNavigation
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.pausesLocationUpdatesAutomatically = false

        let backgroundModes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String]
        if let modes = backgroundModes, modes.contains("location") {
            manager.allowsBackgroundLocationUpdates = true
        }
    }

    private func requestAuthorizationIfNeeded() {
        if LocationManager.authorizationStatus() == .notDetermined {
            manager.requestAlwaysAuthorization()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            return
        }

        for request in requests {
            request(location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        debugPrint(error)
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.manager.startUpdatingLocation()
    }
}

extension LocationManager {
    func subscribe(_ locationHandler: @escaping LocationHandler) {
        requests.append(locationHandler)
        requestAuthorizationIfNeeded()
        manager.startUpdatingLocation()
    }

    func cancel() {
        requests.removeAll()
        manager.stopUpdatingLocation()
    }

    func set(accuracy: LocationAccuracy) {
        switch accuracy {
        case .low:
            manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        case .medium:
            manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        default:
            manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        }
    }

    var updatingLocation: Bool {
        return !requests.isEmpty
    }

    static func authorizationStatus(
        _ locationManagerProtocol: CLLocationManagerProtocol.Type = CLLocationManager.self) -> CLAuthorizationStatus {
        return locationManagerProtocol.authorizationStatus()
    }

    static func locationServicesEnabled(
        _ locationManagerProtocol: CLLocationManagerProtocol.Type = CLLocationManager.self) -> Bool {
        return locationManagerProtocol.locationServicesEnabled()
    }
}
