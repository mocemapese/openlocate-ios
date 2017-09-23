//
//  NetworkInfo.swift
//  OpenLocate
//
//  Created by Mohammad Kurabi on 9/22/17.
//  Copyright © 2017 OpenLocate. All rights reserved.
//

import Foundation
import SystemConfiguration.CaptiveNetwork

struct NetworkInfo {
    
    var bssid: String?
    var ssid: String?
    
    static func currentNetworkInfo() -> NetworkInfo {
        var networkInfo = NetworkInfo()
        if let interface = CNCopySupportedInterfaces() {
            for i in 0..<CFArrayGetCount(interface) {
                let interfaceName: UnsafeRawPointer = CFArrayGetValueAtIndex(interface, i)
                let rec = unsafeBitCast(interfaceName, to: AnyObject.self)
                if let unsafeInterfaceData = CNCopyCurrentNetworkInfo("\(rec)" as CFString),
                    let interfaceData = unsafeInterfaceData as? [String : AnyObject] {
                    networkInfo.bssid = interfaceData["BSSID"] as? String
                    networkInfo.ssid = interfaceData["SSID"] as? String
                } else {
                    // not connected wifi
                }
            }
        }
        return networkInfo
    }
}
