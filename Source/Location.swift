//
//  Location.swift
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

/// JsonParameterType defines a protocol with getter for json

protocol JsonParameterType {
    var json: Parameters { get }
}

/// DataType defines a protocol to convert struct to data

protocol DataType {
    var data: Data { get }
}

// MARK: - Provider

enum ProviderType: String {
    case gps
    case network
    case passive
}

// MARK: - Location

/**
 LocationType protocol defines a location type object.
 */

protocol OpenLocateLocationType: JsonParameterType, DataType {

}

struct OpenLocateLocation: OpenLocateLocationType, CustomDebugStringConvertible {

    private struct Keys {
        static let adId = "ad_id"
        static let adOptOut = "ad_opt_out"
        static let adType = "id_type"
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let timeStamp = "utc_timestamp"
        static let horizontalAccuracy = "horizontal_accuracy"
        static let verticalAccuracy = "vertical_accuracy"
        static let altitude = "altitude"
    }

    private let idTypeValue = "idfa"

    private let location: CLLocation
    private let advertisingInfo: AdvertisingInfo
    
    var debugDescription: String {
        return "OpenLocateLocation(location: \(location), advertisingInfo: \(advertisingInfo))"
    }

    init(location: CLLocation, advertisingInfo: AdvertisingInfo) {
        self.location = location
        self.advertisingInfo = advertisingInfo
    }
    
}

extension OpenLocateLocation {
    var json: Parameters {
        return [
            Keys.adId: advertisingInfo.advertisingId.lowercased(),
            Keys.adOptOut: advertisingInfo.isLimitedAdTrackingEnabled,
            Keys.adType: idTypeValue,
            Keys.latitude: location.coordinate.latitude,
            Keys.longitude: location.coordinate.longitude,
            Keys.timeStamp: Int(location.timestamp.timeIntervalSince1970),
            Keys.horizontalAccuracy: location.horizontalAccuracy
        ]
    }
}

extension OpenLocateLocation {
    init(data: Data) {
        let unwrappedCoding = NSKeyedUnarchiver.unarchiveObject(with: data) as? Coding
        let coding = unwrappedCoding!

        self.location = CLLocation(
            coordinate: CLLocationCoordinate2DMake(coding.latitude, coding.longitude),
            altitude: coding.altitude,
            horizontalAccuracy: coding.horizontalAccuracy,
            verticalAccuracy: coding.verticalAccuracy,
            timestamp: Date(timeIntervalSince1970: coding.timeStamp)
        )
        self.advertisingInfo = AdvertisingInfo.Builder()
            .set(advertisingId: coding.advertisingId)
            .set(isLimitedAdTrackingEnabled: coding.isLimitedAdTrackingEnabled)
            .build()
    }

    var data: Data {
        return NSKeyedArchiver.archivedData(withRootObject: Coding(self))
    }

    @objc(OL) private class Coding: NSObject, NSCoding {
        let latitude: CLLocationDegrees
        let longitude: CLLocationDegrees
        let timeStamp: TimeInterval
        let horizontalAccuracy: CLLocationAccuracy
        let verticalAccuracy: CLLocationAccuracy
        let altitude: CLLocationDistance
        let advertisingId: String
        let isLimitedAdTrackingEnabled: Bool

        init(_ location: OpenLocateLocation) {
            latitude = location.location.coordinate.latitude
            longitude = location.location.coordinate.longitude
            timeStamp = location.location.timestamp.timeIntervalSince1970
            horizontalAccuracy = location.location.horizontalAccuracy
            verticalAccuracy = location.location.verticalAccuracy
            altitude = location.location.altitude
            advertisingId = location.advertisingInfo.advertisingId
            isLimitedAdTrackingEnabled = location.advertisingInfo.isLimitedAdTrackingEnabled
        }

        required init?(coder aDecoder: NSCoder) {
            latitude = aDecoder.decodeDouble(forKey: OpenLocateLocation.Keys.latitude)
            longitude = aDecoder.decodeDouble(forKey: OpenLocateLocation.Keys.longitude)
            timeStamp = aDecoder.decodeDouble(forKey: OpenLocateLocation.Keys.timeStamp)
            horizontalAccuracy = aDecoder.decodeDouble(forKey: OpenLocateLocation.Keys.horizontalAccuracy)
            verticalAccuracy = aDecoder.decodeDouble(forKey: OpenLocateLocation.Keys.verticalAccuracy)
            altitude = aDecoder.decodeDouble(forKey: OpenLocateLocation.Keys.altitude)
            advertisingId = (aDecoder.decodeObject(forKey: OpenLocateLocation.Keys.adId) as? String)!
            isLimitedAdTrackingEnabled = aDecoder.decodeBool(forKey: OpenLocateLocation.Keys.adOptOut)
        }

        func encode(with aCoder: NSCoder) {
            aCoder.encode(latitude, forKey: OpenLocateLocation.Keys.latitude)
            aCoder.encode(longitude, forKey: OpenLocateLocation.Keys.longitude)
            aCoder.encode(timeStamp, forKey: OpenLocateLocation.Keys.timeStamp)
            aCoder.encode(horizontalAccuracy, forKey: OpenLocateLocation.Keys.horizontalAccuracy)
            aCoder.encode(verticalAccuracy, forKey: OpenLocateLocation.Keys.verticalAccuracy)
            aCoder.encode(altitude, forKey: OpenLocateLocation.Keys.altitude)
            aCoder.encode(advertisingId, forKey: OpenLocateLocation.Keys.adId)
            aCoder.encode(isLimitedAdTrackingEnabled, forKey: OpenLocateLocation.Keys.adOptOut)
        }
    }
}
