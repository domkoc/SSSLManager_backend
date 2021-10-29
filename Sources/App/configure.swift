import Fluent
import FluentSQLiteDriver
import Vapor
import SendGrid

// configures your application
public func configure(_ app: Application) throws {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.dateEncodingStrategy = .iso8601
    
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .iso8601
    
    ContentConfiguration.global.use(encoder: encoder, for: .json)
    ContentConfiguration.global.use(decoder: decoder, for: .json)
    
    app.databases.use(.sqlite(.file("SSSLManager.sqlite")), as: .sqlite)
    
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))
    
    app.routes.caseInsensitive = true
    app.migrations.add(CreateUsers())
//    app.migrations.add(CreateDinners())
//    app.migrations.add(CreateDinnerInviteePivotMigration())
    app.migrations.add(CreateTokens())
//    app.migrations.add(CreateTodo())
    app.migrations.add(CreateEvent())
    app.migrations.add(CreateEventApplicantsPivot())
    app.migrations.add(CreateEventWorkersPivot())
    app.migrations.add(CreateSubEventPivot())
    
    app.logger.logLevel = .debug
    
    try app.autoMigrate().wait()
    
    try routes(app)
    print("routes:")
    app.routes.all.forEach { route in
        print(route)
    }
    
    app.sendgrid.initialize()
}
