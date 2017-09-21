//
//  SafeGraph.swift
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
import OpenLocate
import Alamofire

private let baseUrl = "https://api.safegraph.com/v1"

public struct SafeGraphConfiguration {
    public let uuid: UUID
    public let token: String

    public init(uuid: UUID, token: String) {
        self.uuid = uuid
        self.token = token
    }
}

extension SafeGraphConfiguration: Configuration {
    public var url: String {
        return "\(baseUrl)/provider/\(uuid.uuidString.lowercased())/devicelocation"
    }

    public var headers: Headers? {
        if token.isEmpty {
            return nil
        }

        return ["Authorization": "Bearer \(token)"]
    }

    public var valid: Bool {
        return headers != nil
    }
}

struct SafeGraphPlace {
    let placeId: String
    let name: String
    let streetAddress: String
    let city: String
    let state: String
    let zipCode: Int
    let naicsCategory: String
    let naicsSubCategory: String
    let naicsCode: Int
    let distance: Double

    init(json: [String: Any]) {
        placeId = (json["id"] as? String)!
        name = (json["name"] as? String)!
        streetAddress = (json["street_address"] as? String)!
        city = (json["city"] as? String)!
        state = (json["state"] as? String)!
        zipCode = (json["zip_code"] as? Int)!
        naicsCategory = (json["naics_category"] as? String)!
        naicsSubCategory = (json["naics_subcategory"] as? String)!
        naicsCode = (json["naics_code"] as? Int)!
        distance = (json["distance"] as? Double)!
    }
}

typealias SafePlacesCompletionHandler = ([SafeGraphPlace]?, Error?) -> Void

enum SafeGraphError: Error {
    case placesNotFound
}

class SafeGraphStore {
    static let shared = SafeGraphStore()

    func fetchNearbyPlaces(location: OpenLocateLocation, completion: @escaping SafePlacesCompletionHandler) {

        Alamofire.request(
            "https://api.safegraph.com/places/v1/nearby",
            parameters: [
                "advertising_id": location.advertisingId,
                "advertising_id_type": location.advertisingIdType,
                "latitude": location.latitude,
                "longitude": location.longitude,
                "horizontal_accuracy": location.horizontalAccuracy
            ],
            headers: ["Authorization": "Bearer <YOUR_TOKEN>"]
        )
            .responseJSON { response in
                debugPrint(response)
                guard let json = response.result.value as? [String: Any],
                    let placesJson = json["places"] as? [Any], !placesJson.isEmpty else {
                    completion(nil, SafeGraphError.placesNotFound)
                    return
                }

                var places = [SafeGraphPlace]()
                for placeJson in placesJson {
                    let place = (placeJson as? [String: Any])!
                    places.append(SafeGraphPlace(json: place))
                }

                completion(places, nil)
        }
    }
}
