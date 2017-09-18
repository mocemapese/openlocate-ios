//
//  SafeGraph.swift
//  iOS Example
//
//  Created by Ulhas Mandrawadkar on 23/08/17.
//  Copyright © 2017 OpenLocate. All rights reserved.
//

import Foundation
import OpenLocate

// SafeGraph Configuration

private let baseUrl = "https://api.safegraph.com/v1"

public struct SafeGraphConfiguration: Configuration {
    
    public let uuid: UUID
    public let token: String

    public init?() {
        if let uuidString = Bundle.main.object(forInfoDictionaryKey: "ProviderId") as? String,
            let token = Bundle.main.object(forInfoDictionaryKey: "Token") as? String,
            let uuid = UUID(uuidString: uuidString) {
            
            self.init(uuid: uuid, token: token)
        } else {
            return nil
        }
    }
    
    public init(uuid: UUID, token: String) {
        self.uuid = uuid
        self.token = token
    }
    
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
    
    public var transmissionInterval: TimeInterval {
        return 8 * 60 * 60
    }
}
