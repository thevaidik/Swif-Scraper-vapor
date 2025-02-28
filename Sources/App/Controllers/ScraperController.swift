import Vapor

struct ScraperController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let scrapers = routes.grouped("api", "scrape")
        scrapers.post(use: scrape)
        scrapers.get("health", use: health)
    }
    
    func scrape(req: Request) throws -> EventLoopFuture<ScraperResponse> {
        let scraperRequest = try req.content.decode(ScraperRequest.self)
        let scraperService = ScraperService(eventLoop: req.eventLoop)
        return scraperService.scrape(request: scraperRequest)
    }
    
    func health(req: Request) -> String {
        return "Scraper service is running"
    }
}