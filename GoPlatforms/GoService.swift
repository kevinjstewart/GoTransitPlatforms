//
//  GoService.swift
//  GoPlatforms
//
//  Created by Kevin Stewart on 2017-05-18.
//  Copyright © 2017 Kevin Stewart. All rights reserved.
//

import Foundation

struct GoService: CustomStringConvertible {
    
    let vehicleType: VehicleType
    let route: String
    let departureTime: Date
    let platform: Int?
    
    enum VehicleType: String {
        case train = "Train"
        case bus = "Bus"
    }
    
    var description: String {
        let time = DateFormatter.timeFormatter.string(from: departureTime)
        return "\(route) - \(vehicleType.rawValue) - \(time) - \(platform ?? 0)"
    }
}
