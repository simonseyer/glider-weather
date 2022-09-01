import Foundation
import ArgumentParser
import ServerCore

let defaultPort = 8888

struct MainCLI: ParsableCommand {
    @Option(name: .shortAndLong, help: "TCP Port to listen on (Default: \(defaultPort))")
    var port: Int = defaultPort
    
    
    func run() throws {
        let config = ServerConfig(port: port)
        let server = Server(config)
        server.run()
    }
}

MainCLI.main()
