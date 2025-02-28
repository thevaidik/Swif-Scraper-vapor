import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        return "Swift Scraper Microservice"
    }

    try app.register(collection: ScraperController())
}