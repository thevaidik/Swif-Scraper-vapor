import Vapor

struct ScraperRequest: Content {
    let url: String
    let selectors: [String]?
    let javascript: Bool?
    let headers: [String: String]?
    let timeout: Int?
    
    // Optional parameters for advanced scraping
    let waitForSelector: String?
    let proxy: String?
}

struct ScraperResponse: Content {
    let url: String
    let data: [String: [String]]
    let html: String?
    let error: String?
    let executionTime: Double
}