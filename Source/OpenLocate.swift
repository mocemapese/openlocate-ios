//
//  OpenLocate.swift
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
import AdSupport
import CoreLocation

public typealias LocationCompletionHandler = (OpenLocateLocation?, Error?) -> Void

private protocol OpenLocateType {

    static var shared: OpenLocate { get }

    var locationAccuracy: LocationAccuracy { get set }
    var transmissionInterval: TimeInterval { get set }
    var locationInterval: TimeInterval { get set }

    func startTracking() throws
    func stopTracking()

    func fetchCurrentLocation(completion: LocationCompletionHandler) throws

    func add(location: CLLocation) throws
    func add(locations: [CLLocation]) throws

    func initialize(configuration: Configuration) throws

    var tracking: Bool { get }
}

public enum LocationAccuracy: String {
    case high
    case medium
    case low
}

private let defaultTransmissionInterval: TimeInterval = 300
private let defaultLocationAccuracy = LocationAccuracy.high
private let defaultLocationInterval: TimeInterval = 120

public final class OpenLocate: OpenLocateType {

    public static let shared = OpenLocate()

    private var configuration: Configuration?
    private var locationService: LocationServiceType?

    public var locationAccuracy = defaultLocationAccuracy {
        didSet {
            locationService?.locationAccuracy = locationAccuracy
        }
    }

    public var transmissionInterval = defaultTransmissionInterval {
        didSet {
            locationService?.transmissionInterval = transmissionInterval
        }
    }

    public var locationInterval = defaultLocationInterval {
        didSet {
            locationService?.locationInterval = locationInterval
        }
    }

    public func initialize(configuration: Configuration) throws {
        try validate(configuration: configuration)
        self.configuration = configuration
    }
}

extension OpenLocate {
    private func initLocationService(configuration: Configuration) {
        let httpClient = HttpClient()
        let scheduler = TaskScheduler(timeInterval: transmissionInterval)

        let locationDataSource: LocationDataSourceType

        do {
            let database = try SQLiteDatabase.openLocateDatabase()
            locationDataSource = LocationDatabase(database: database)
        } catch _ {
            locationDataSource = LocationList()
        }

        self.locationService = LocationService(
            postable: httpClient,
            locationDataSource: locationDataSource,
            scheduler: scheduler,
            url: configuration.url,
            headers: configuration.headers,
            advertisingInfo: advertisingInfo,
            locationAccuracy: locationAccuracy,
            locationInterval: locationInterval,
            transmissionInterval: transmissionInterval
        )
    }

    public func startTracking() throws {
        try validate()

        startLocationService()
        if locationService?.locationManager == nil {
            locationService?.locationManager = LocationManager()
        }
    }

    private func startLocationService() {
        if locationService == nil {
            initLocationService(configuration: configuration!)
            locationService?.start()
        }
    }

    private func validate() throws {
        try validate(configuration: configuration)
        try validateLocationEnabled()
        try validateLocationAuthorization()
        try validateLocationAuthorizationKeys()
    }

    public func stopTracking() {
        guard let service = locationService else {
            debugPrint("Trying to stop server even if it was never started.")
            return
        }

        service.stop()
        self.locationService = nil
    }

    public var tracking: Bool {
        return locationService != nil
    }

    private var advertisingInfo: AdvertisingInfo {
        let manager = ASIdentifierManager.shared()
        let advertisingInfo = AdvertisingInfo.Builder()
            .set(advertisingId: manager.advertisingIdentifier.uuidString)
            .set(isLimitedAdTrackingEnabled: manager.isAdvertisingTrackingEnabled)
            .build()

        return advertisingInfo
    }
}

extension OpenLocate {
    public func fetchCurrentLocation(completion: (OpenLocateLocation?, Error?) -> Void) throws {
        try validateLocationEnabled()
        try validateLocationAuthorization()
        try validateLocationAuthorizationKeys()

        let manager = LocationManager()
        let lastLocation = manager.lastLocation

        guard let location = lastLocation else {
            completion(
                nil,
                OpenLocateError.locationFailure(message: OpenLocateError.ErrorMessage.locationFailureMessage))
            return
        }

        let openlocateLocation = OpenLocateLocation(location: location, advertisingInfo: advertisingInfo)
        completion(openlocateLocation, nil)
    }
}

extension OpenLocate {

    private func validate(configuration: Configuration?) throws {
        // throw error if token is empty
        if configuration == nil || !configuration!.valid {
            debugPrint(OpenLocateError.ErrorMessage.invalidConfigurationMessage)
            throw OpenLocateError.invalidConfiguration(
                message: OpenLocateError.ErrorMessage.invalidConfigurationMessage
            )
        }
    }

    private func validateLocationAuthorization() throws {
        if LocationService.isAuthorizationDenied() {
            debugPrint(OpenLocateError.ErrorMessage.unauthorizedLocationMessage)
            throw OpenLocateError.locationUnAuthorized(
                message: OpenLocateError.ErrorMessage.unauthorizedLocationMessage
            )
        }
    }

    private func validateLocationAuthorizationKeys() throws {
        if !LocationService.isAuthorizationKeysValid() {
            debugPrint(OpenLocateError.ErrorMessage.missingAuthorizationKeysMessage)
            throw OpenLocateError.locationMissingAuthorizationKeys(
                message: OpenLocateError.ErrorMessage.missingAuthorizationKeysMessage
            )
        }
    }

    private func validateLocationEnabled() throws {
        if !LocationService.isEnabled() {
            debugPrint(OpenLocateError.ErrorMessage.locationDisabledMessage)
            throw OpenLocateError.locationDisabled(
                message: OpenLocateError.ErrorMessage.locationDisabledMessage
            )
        }
    }
}

extension OpenLocate {
    func add(location: CLLocation) throws {
        try validate()

        let openLocateLocation = OpenLocateLocation(location: location, advertisingInfo: advertisingInfo)
        startLocationService()
        locationService?.add(locations: [openLocateLocation])
    }

    func add(locations: [CLLocation]) throws {
        try validate()

        let openLocateLocations = locations.map { OpenLocateLocation(location: $0, advertisingInfo: advertisingInfo) }
        startLocationService()
        locationService?.add(locations: openLocateLocations)
    }
}
