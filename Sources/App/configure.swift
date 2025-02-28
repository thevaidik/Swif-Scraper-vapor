import Vapor
import NIO

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // Configure rate limiting for protection
    let rateLimiter = RateLimiter(maxRequests: 100, per: .minutes(1))
    app.middleware.use(rateLimiter)
    
    // Register routes
    try routes(app)
}