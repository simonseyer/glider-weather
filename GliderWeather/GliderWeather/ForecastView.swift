//
//  ForecastView.swift
//  GliderWeather
//
//  Created by Simon Seyer on 27.06.22.
//

import SwiftUI
import Charts

extension TemperatureForecast {
    var temperatureRange: ClosedRange<Int> {
        let temperatures = forecasts.flatMap { $0.temperatures.map { $0.temperature }  }
        let min = Int(temperatures.min() ?? -20)
        let max = Int(temperatures.max() ?? 40)
        return min...max
    }
}

struct ForecastView: View {

    let forecast: TemperatureForecast
    @State var dateSelection: Double = 0

    private var selectedForecast: TemperatureForecast.Forecast {
        forecast.forecasts[Int(dateSelection)]
    }

    var dates: [Date] {
        forecast.forecasts.map { $0.date }
    }

    var body: some View {
        VStack {
            Text("Last update: \(forecast.lastUpdate)")
                .font(.caption)
            Chart {
                ForEach(selectedForecast.temperatures) { data in
                    LineMark(x: .value("Temperature", data.temperature), y: .value("Altitude", data.altitude))


                }
                .interpolationMethod(.catmullRom)

//                .symbol(Circle())
//                LineMark(x: .value("Temperature", 0), y: .value("Altitude", 0))
//                    .foregroundStyle(.green)
            }.chartForegroundStyleScale(range: 0...10).foregroundColor(.green)


            .chartXScale(domain: forecast.temperatureRange)
//            .padding()
//            .chartYScale(range: -1000...60000)
            Slider(value: $dateSelection, in: 0.0...Double(forecast.forecasts.count - 1), step: 1)
            HStack {
                Text(selectedForecast.date, style: .date)
                Text(selectedForecast.date, style: .time)
            }
        }
        .padding()
    }
}

struct ForecastView_Previews: PreviewProvider {

    static let decoder = JSONDecoder()
    static let mockURL = Bundle.main.url(forResource: "forecast", withExtension: "json")!
    static let mockData = try! decoder.decode(TemperatureForecast.self, from: Data(contentsOf: mockURL))

    static var previews: some View {
        ForecastView(forecast: mockData)
    }
}
