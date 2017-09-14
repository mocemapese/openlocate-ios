//
//  Place.swift
//  OpenLocate
//
//  Created by Ulhas Mandrawadkar on 13/09/17.
//  Copyright © 2017 OpenLocate. All rights reserved.
//

import Foundation
import CoreLocation

public protocol Place {
    var placeId: String { get }
    var location: CLLocationCoordinate2D { get }
    var street: String { get }
    var city: String { get }
    var state: String { get }
    var country: String { get }
    var zip: String { get }
}
