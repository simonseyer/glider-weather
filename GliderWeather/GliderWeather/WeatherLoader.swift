//
//  WeatherLoader.swift
//  GliderWeather
//
//  Created by Simon Seyer on 26.06.22.
//

import Foundation
import CoreLocation

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

extension TemperatureForecast.Forecast: Identifiable {
    var id: Date {
        date
    }
}

struct Location: Codable {
    let latitude: Double
    let longitude: Double
}

extension TemperatureForecast.Temperature: Identifiable {
    var id: Double {
        altitude
    }
}

extension Location {
    var clLocation: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}

class WeatherLoader: ObservableObject {

    func fetchTempeatureForecast(_ location: CLLocation) async -> TemperatureForecast? {
        do {
            let url = URL(string: "http://192.168.0.213:8888/temperatures?latitude=\(location.coordinate.latitude)&longitude=\(location.coordinate.longitude)")!
            let (data, response) = try await URLSession.shared.data(from: url)
            print(response)
            let decoder = JSONDecoder()
            return try decoder.decode(TemperatureForecast.self, from: data)
        } catch {
            print(error)
            return nil
        }
    }
}
