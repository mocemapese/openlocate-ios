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
    var transmissionInterval: TimeInterval { get set }

    var isStarted: Bool { get }

    func start()
    func stop()

    func fetchLocation(onCompletion: @escaping ((Bool) -> Void))
}

private let locationsKey = "locations"

final class LocationService: LocationServiceType {

    let isStartedKey = "OpenLocate_isStarted"
    let endpointsInfoKey = "OpenLocate_EndpointsInfo"
    let endpointLastTransmitDate = "lastTransmitDate"

    let collectingFieldsConfiguration: CollectingFieldsConfiguration

    var transmissionInterval: TimeInterval

    var isStarted: Bool {
        return UserDefaults.standard.bool(forKey: isStartedKey)
    }

    private let locationManager: LocationManagerType
    private let httpClient: Postable
    private let locationDataSource: LocationDataSourceType
    private var advertisingInfo: AdvertisingInfo
    private let executionQueue: DispatchQueue = DispatchQueue(label: "openlocate.queue.async", qos: .background)

    private let endpoints: [Configuration.Endpoint]
    private var isPostingLocations = false
    private var endpointsInfo: [String: [String: Any]]

    private let dispatchGroup = DispatchGroup()
    private var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid

    init(
        postable: Postable,
        locationDataSource: LocationDataSourceType,
        endpoints: [Configuration.Endpoint],
        advertisingInfo: AdvertisingInfo,
        locationManager: LocationManagerType,
        transmissionInterval: TimeInterval,
        logConfiguration: CollectingFieldsConfiguration) {

        httpClient = postable
        self.locationDataSource = locationDataSource
        self.locationManager = locationManager
        self.advertisingInfo = advertisingInfo
        self.endpoints = endpoints
        self.transmissionInterval = transmissionInterval
        self.collectingFieldsConfiguration = logConfiguration

        if let endpointsInfo = UserDefaults.standard.dictionary(forKey: endpointsInfoKey) as? [String: [String: Any]] {
            self.endpointsInfo = endpointsInfo
        } else {
            self.endpointsInfo = [String: [String: Any]]()
        }
    }

    func start() {
        debugPrint("Location service started for urls : \(endpoints.map({$0.url}))")

        locationManager.subscribe { [weak self] locations in
            self?.executionQueue.async {
                guard let strongSelf = self else { return }

                let collectingFields = DeviceCollectingFields.configure(with: strongSelf.collectingFieldsConfiguration)

                let openLocateLocations: [OpenLocateLocation] = locations.map {
                    let info = CollectingFields.Builder(configuration: strongSelf.collectingFieldsConfiguration)
                        .set(location: $0.location)
                        .set(network: NetworkInfo.currentNetworkInfo())
                        .set(deviceInfo: collectingFields)
                        .build()

                    return OpenLocateLocation(timestamp: $0.location.timestamp,
                                              advertisingInfo: strongSelf.advertisingInfo,
                                              collectingFields: info,
                                              context: $0.context)
                }

                strongSelf.locationDataSource.addAll(locations: openLocateLocations)

                //debugPrint(strongSelf.locationDataSource.all())

                strongSelf.postLocationsIfNeeded()
            }
        }

        UserDefaults.standard.set(true, forKey: isStartedKey)
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
    }

    func stop() {
        locationManager.cancel()
        locationDataSource.clear()

        UserDefaults.standard.set(false, forKey: isStartedKey)
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalNever)
    }

    func fetchLocation(onCompletion: @escaping ((Bool) -> Void)) {
        locationManager.fetchLocation(onCompletion: onCompletion)
    }

}

extension LocationService {

    func postLocationsIfNeeded() {
        if let earliestIndexedLocation = locationDataSource.first() {
            do {
                let earliestLocation = try OpenLocateLocation(data: earliestIndexedLocation.data)
                if abs(earliestLocation.timestamp.timeIntervalSinceNow) > self.transmissionInterval {
                    postLocations()
                }
            } catch {
                debugPrint(error)
            }
        }
    }

    private func postLocations() {

        if isPostingLocations == true || endpoints.isEmpty { return }

        beginBackgroundTask()

        for endpoint in endpoints {
            dispatchGroup.enter()
            do {
                let date = lastKnownTransmissionDate(for: endpoint)
                let locations = locationDataSource.all(since: date)

                let params = [locationsKey: locations.map { $0.json }]
                let requestParameters = URLRequestParamters(url: endpoint.url.absoluteString,
                                                            params: params,
                                                            queryParams: nil,
                                                            additionalHeaders: endpoint.headers)
                try httpClient.post(
                    parameters: requestParameters,
                    success: {  [weak self] _, _ in
                        if let lastLocation = locations.last {
                            self?.setLastKnownTransmissionDate(for: endpoint, with: lastLocation.timestamp)
                        }
                        self?.dispatchGroup.leave()
                    },
                    failure: { [weak self] _, error in
                        debugPrint("failure in posting locations!!! Error: \(error)")
                        self?.dispatchGroup.leave()
                    }
                )
            } catch let error {
                print(error.localizedDescription)
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let strongSelf = self else { return }

            strongSelf.locationDataSource.clear(before: strongSelf.transmissionDateCutoff())
            strongSelf.isPostingLocations = false
            strongSelf.endBackgroundTask()
        }
    }

    private func lastKnownTransmissionDate(for endpoint: Configuration.Endpoint) -> Date {
        let key = infoKeyForEndpoint(endpoint)
        if let endpointInfo = endpointsInfo[key],
            let date = endpointInfo[endpointLastTransmitDate] as? Date, date <= Date() {

            return date
        }
        return Date.distantPast
    }

    private func setLastKnownTransmissionDate(for endpoint: Configuration.Endpoint, with date: Date) {
        let key = infoKeyForEndpoint(endpoint)
        if var endpointInfo = endpointsInfo[key] {
            endpointInfo[endpointLastTransmitDate] = date
            persistEndPointsInfo()
        }
    }

    private func transmissionDateCutoff() -> Date {
        var cutoffDate = Date()
        for (_, endpointInfo) in endpointsInfo {
            if let date = endpointInfo[endpointLastTransmitDate] as? Date, date < cutoffDate {
                cutoffDate = date
            }
        }
        
        if let maxCutoffDate = Calendar.current.date(byAdding: .day, value: -10, to: Date()),
            maxCutoffDate < cutoffDate {
            
            return maxCutoffDate
        }
        return cutoffDate
    }

    private func infoKeyForEndpoint(_ endpoint: Configuration.Endpoint) -> String {
        return endpoint.url.absoluteString.lowercased()
    }

    private func persistEndPointsInfo() {
        UserDefaults.standard.set(endpointsInfo, forKey: endpointsInfoKey)
        UserDefaults.standard.synchronize()
    }

    private func beginBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = UIBackgroundTaskInvalid
    }

    static func isAuthorizationKeysValid() -> Bool {
        let always = Bundle.main.object(forInfoDictionaryKey: "NSLocationAlwaysUsageDescription")
        let inUse = Bundle.main.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription")
        let alwaysAndinUse = Bundle.main.object(forInfoDictionaryKey: "NSLocationAlwaysAndWhenInUseUsageDescription")

        if #available(iOS 11, *) {
            return always != nil && inUse != nil && alwaysAndinUse != nil
        }

        return always != nil
    }
}
