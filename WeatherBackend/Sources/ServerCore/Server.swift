import Kitura
import KituraContracts
import MongoSwiftSync
import NIO
import Foundation

struct TemperatureDocument: Codable {
    let _id: BSON
    let location: Location
    let analysis_date: Date
    let altitude: Double
    let temperatures: [TemperatureForecast]

    struct Location: Codable, Equatable {
        let type: String
        let coordinates: [Double]
    }

    struct TemperatureForecast: Codable {
        let forecast_date: Date
        let temperature: Double
    }
}

extension Sequence {
    func sorted<T: Comparable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        sorted { a, b in
            a[keyPath: keyPath] < b[keyPath: keyPath]
        }
    }
}

public class Server {
    private let router: Router
    private let config: ServerConfig
//    private let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 4)
    private let mongoClient: MongoClient
    private let database: MongoDatabase
    private let temperatureCollection: MongoCollection<TemperatureDocument>

    public init(_ config: ServerConfig) {
        self.config = config
        self.mongoClient =  try! MongoClient()
        self.database = mongoClient.db("weather")
        self.temperatureCollection = database.collection("temperatures", withType: TemperatureDocument.self)
        self.router = Router()
    }
    
    public func run() {
        router.get("/temperatures", handler: temperatureRequestHandler)
        
        let server = Kitura.addHTTPServer(onPort: config.port, onAddress: "192.168.0.213", with: router)
//        try! server.setEventLoopGroup(eventLoopGroup)
        
        Kitura.run()
    }

    func temperatureRequestHandler(location: Location?, completion: @escaping (TemperatureForecast?, RequestError?) -> Void) {

        guard let location = location else {
            completion(nil, .badRequest)
            return
        }

        let query: BSONDocument = [
            "location": [
                "$nearSphere": [
                    "$geometry": [
                        "type": "Point",
                        "coordinates": [
                            BSON(floatLiteral: location.longitude),
                            BSON(floatLiteral: location.latitude)
                        ]
                    ],
                    "$maxDistance": 20000
                ]
            ]
        ]
        let documents = try! temperatureCollection.find(query)

        var forecasts: [Date: [TemperatureForecast.Temperature]] = [:]
        var lastUpdate: Date?
        var forecastLocation: TemperatureDocument.Location?

        for result in documents {
            let doc = try! result.get()
            if lastUpdate == nil {
                lastUpdate = doc.analysis_date
            } else if lastUpdate != doc.analysis_date {
                break
            }

            if forecastLocation == nil {
                forecastLocation = doc.location
            } else if forecastLocation != doc.location {
                break
            }

            for temperature in doc.temperatures {
                var temperatures = forecasts[temperature.forecast_date] ?? []
                temperatures.append(TemperatureForecast.Temperature(altitude: doc.altitude, temperature: temperature.temperature))
                forecasts[temperature.forecast_date] = temperatures
            }
        }

        guard let forecastLocation = forecastLocation, let lastUpdate = lastUpdate else {
            completion(nil, .notFound)
            return
        }

        let forecast = TemperatureForecast(location: .init(latitude: forecastLocation.coordinates[1],
                                                           longitude: forecastLocation.coordinates[0]),
                                       lastUpdate: lastUpdate,
                                       forecasts: forecasts.map({ (date, temperatures) in
            TemperatureForecast.Forecast(date: date, temperatures: temperatures.sorted(by: \.altitude))
        }).sorted(by: \.date)
        )

        completion(forecast, nil)
    }

    deinit {
//        try? mongoClient.
        cleanupMongoSwift()
//        try? eventLoopGroup.syncShutdownGracefully()
    }
}

extension Location: QueryParams {

}
