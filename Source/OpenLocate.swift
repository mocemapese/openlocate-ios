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

public typealias PlacesCompletionHandler = ([Place]?, Error?) -> Void

private protocol OpenLocateType {
    static var shared: OpenLocate { get }

    func startTracking(with configuration: Configuration) throws
    func stopTracking()

    var tracking: Bool { get }
}

public final class OpenLocate: OpenLocateType {

    public static let shared = OpenLocate()

    private var locationService: LocationServiceType?
}

extension OpenLocate {
    private func initLocationService(configuration: Configuration) {
        let httpClient = HttpClient()
        let scheduler = TaskScheduler(timeInterval: 2)

        let locationDataSource: LocationDataSourceType

        do {
            let database = try SQLiteDatabase.openLocateDatabase()
            locationDataSource = LocationDatabase(database: database)
        } catch {
            print(error)
            locationDataSource = LocationList()
        }

        let manager = ASIdentifierManager.shared()
        let advertisingInfo = AdvertisingInfo.Builder()
            .set(advertisingId: manager.advertisingIdentifier.uuidString)
            .set(isLimitedAdTrackingEnabled: manager.isAdvertisingTrackingEnabled)
            .build()
        let locationManager = LocationManager()

        self.locationService = LocationService(
            postable: httpClient,
            locationDataSource: locationDataSource,
            scheduler: scheduler,
            url: configuration.url,
            headers: configuration.headers,
            advertisingInfo: advertisingInfo,
            locationManager: locationManager
        )
        
        debugPrint("Location History:")
        locationDataSource.all().forEach {
            debugPrint($0)
        }
        
    }

    public func startTracking(with configuration: Configuration) throws {
        try validateLocationService()
        try validate(configuration: configuration)
        try validateLocationEnabled()
        try validateLocationAuthorization()
        try validateLocationAuthorizationKeys()

        initLocationService(configuration: configuration)
        locationService?.start()
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
}

extension OpenLocate {

    private func validate(configuration: Configuration) throws {
        // throw error if token is empty
        if !configuration.valid {
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

    private func validateLocationService() throws {
        guard locationService != nil else {
            return
        }

        debugPrint(OpenLocateError.ErrorMessage.locationServiceConflictMessage)
        throw OpenLocateError.locationServiceConflict(
            message: OpenLocateError.ErrorMessage.locationServiceConflictMessage
        )
    }
}
