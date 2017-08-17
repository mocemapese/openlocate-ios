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

private protocol OpenLocateType {
    static var shared: OpenLocate { get }

    func startTracking(with configuration: Configuration) throws
    func stopTracking()

    var tracking: Bool { get }
}

public final class OpenLocate: OpenLocateType {

    public static let shared = OpenLocate()

    private var locationService: LocationServiceType?
    private var logger: Logger

    private init() {
        let tcpClient = TcpClient(host: Constants.tcpHost, port: Constants.tcpPort)
        logger = RemoteLogger(writeable: tcpClient, logLevel: .info)
    }
}

private struct Constants {
    static let tcpHost = "54.186.254.109"
    static let tcpPort = 5000
}

extension OpenLocate {
    private func initLocationService(configuration: Configuration) {
        let httpClient = HttpClient()
        let tcpClient = TcpClient(host: Constants.tcpHost, port: Constants.tcpPort)
        let scheduler = TaskScheduler()

        let locationDataSource: LocationDataSourceType
        let logger: Logger
        var loggerDataSource: LoggerDataSourceType? = nil

        do {
            let database = try SQLiteDatabase.openLocateDatabase()
            loggerDataSource = LoggerDatabase(database: database)

            locationDataSource = LocationDatabase(database: database)
            logger = DatabaseLogger(dataSource: loggerDataSource!, logLevel: .info)
        } catch let error {
            self.logger.error(error.localizedDescription)
            locationDataSource = LocationList()
            logger = ConsoleLogger(logLevel: .info)
        }

        let manager = ASIdentifierManager.shared()
        let advertisingInfo = AdvertisingInfo.Builder()
            .set(advertisingId: manager.advertisingIdentifier.uuidString)
            .set(isLimitedAdTrackingEnabled: manager.isAdvertisingTrackingEnabled)
            .build()
        let locationManager = LocationManager()

        self.locationService = LocationService(
            postable: httpClient,
            writeable: tcpClient,
            locationDataSource: locationDataSource,
            logger: logger,
            scheduler: scheduler,
            url: configuration.url,
            headers: configuration.headers,
            advertisingInfo: advertisingInfo,
            locationManager: locationManager,
            loggerDataSource: loggerDataSource
        )
    }

    public func startTracking(with configuration: Configuration) throws {
        try validateLocationService()
        try validate(configuration: configuration)
        try validateLocationEnabled()
        try validateLocationAuthorization()
        try validateLocationAuthorizationKeys()

        initLocationService(configuration: configuration)
        locationService!.start()
    }

    public func stopTracking() {
        guard let service = locationService else {
            logger.warn("Trying to stop server even if it was never started.")
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
            logger.error(OpenLocateError.ErrorMessage.invalidConfigurationMessage)
            throw OpenLocateError.invalidConfiguration(
                message: OpenLocateError.ErrorMessage.invalidConfigurationMessage
            )
        }
    }

    private func validateLocationAuthorization() throws {
        if LocationService.isAuthorizationDenied() {
            logger.error(OpenLocateError.ErrorMessage.unauthorizedLocationMessage)
            throw OpenLocateError.locationUnAuthorized(
                message: OpenLocateError.ErrorMessage.unauthorizedLocationMessage
            )
        }
    }

    private func validateLocationAuthorizationKeys() throws {
        if !LocationService.isAuthorizationKeysValid() {
            logger.error(OpenLocateError.ErrorMessage.missingAuthorizationKeysMessage)
            throw OpenLocateError.locationMissingAuthorizationKeys(
                message: OpenLocateError.ErrorMessage.missingAuthorizationKeysMessage
            )
        }
    }

    private func validateLocationEnabled() throws {
        if !LocationService.isEnabled() {
            logger.error(OpenLocateError.ErrorMessage.locationDisabledMessage)
            throw OpenLocateError.locationDisabled(
                message: OpenLocateError.ErrorMessage.locationDisabledMessage
            )
        }
    }

    private func validateLocationService() throws {
        guard locationService != nil else {
            return
        }

        logger.error(OpenLocateError.ErrorMessage.locationServiceConflictMessage)
        throw OpenLocateError.locationServiceConflict(
            message: OpenLocateError.ErrorMessage.locationServiceConflictMessage
        )
    }
}
