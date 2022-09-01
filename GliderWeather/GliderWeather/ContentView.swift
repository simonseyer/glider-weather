//
//  ContentView.swift
//  GliderWeather
//
//  Created by Simon Seyer on 26.06.22.
//

import SwiftUI

struct ContentView: View {

    @StateObject var weatherLoader = WeatherLoader()
    @StateObject var locationFinder = LocationFinder()
    @FocusState var textFieldFocused: Bool

    @State var temperatureForecast: TemperatureForecast?

    var body: some View {
        VStack(spacing: 0) {

            TextField("Location", text: $locationFinder.searchText)
                .disableAutocorrection(true)
                .textFieldStyle(.roundedBorder)
                .focused($textFieldFocused)


            ZStack(alignment: .top) {
                if let forecast = temperatureForecast {
                    ForecastView(forecast: forecast)

                }

                if textFieldFocused && locationFinder.results.count > 0 {
                    List(selection: $locationFinder.selectedResult) {
                        ForEach(locationFinder.results) { result in
                            VStack(alignment: .leading) {
                                Text(result.title)
                                Text(result.subtitle)
                                    .font(.caption)
                            }
                            .tag(result)
                        }
                    }
                    .frame(height: 300)
                    .listStyle(.plain)
                    .padding([.top, .bottom], 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                    )
                    .padding(EdgeInsets(top: 12,
                                        leading: 2,
                                        bottom: 0,
                                        trailing: 2))
                }
            }

            .onChange(of: locationFinder.location) { newValue in
                if let newValue {
                    textFieldFocused = false
                    Task {
                        temperatureForecast = await weatherLoader.fetchTempeatureForecast(newValue)
                    }
                }
            }
            Spacer()
        }.padding([.leading, .trailing])
            .ignoresSafeArea(.keyboard)
    }
}

struct ContentView_Previews: PreviewProvider {

    static var locationFinder: LocationFinder {
        let finder = LocationFinder()
        finder.searchText = "Frank, Ger"
        return finder
    }

    static var previews: some View {
        ContentView(locationFinder: locationFinder)
    }
}
