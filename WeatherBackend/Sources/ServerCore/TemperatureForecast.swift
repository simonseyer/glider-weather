//
//  TemperatureForecast.swift
//  
//
//  Created by Simon Seyer on 26.06.22.
//

import Foundation

struct TemperatureForecast: Codable {
    let location: Location
    let lastUpdate: Date
    let forecasts: [Forecast]

    struct Forecast: Codable {
        let date: Date
        let temperatures: [Temperature]
    }

    struct Temperature: Codable {
        let altitude: Double
        let temperature: Double
    }
}

struct Location: Codable {
    let latitude: Double
    let longitude: Double
}
