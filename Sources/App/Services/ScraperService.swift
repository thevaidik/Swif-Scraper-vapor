import Vapor
import Foundation
import SwiftSoup
import NIO

class ScraperService {
    private let eventLoop: EventLoop
    
    init(eventLoop: EventLoop) {
        self.eventLoop = eventLoop
    }
    
    func scrape(request: ScraperRequest) -> EventLoopFuture<ScraperResponse> {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        guard let url = URL(string: request.url) else {
            return eventLoop.makeFailedFuture(ScraperError.invalidURL)
        }
        
        return fetchHTML(from: url, headers: request.headers, timeout: request.timeout)
            .flatMapThrowing { html in
                let data = try self.extractData(from: html, selectors: request.selectors ?? [])
                let executionTime = CFAbsoluteTimeGetCurrent() - startTime
                
                return ScraperResponse(
                    url: request.url,
                    data: data,
                    html: request.javascript == true ? nil : html,
                    error: nil,
                    executionTime: executionTime
                )
            }
            .flatMapError { error in
                let executionTime = CFAbsoluteTimeGetCurrent() - startTime
                return self.eventLoop.makeSucceededFuture(
                    ScraperResponse(
                        url: request.url,
                        data: [:],
                        html: nil,
                        error: "\(error)",
                        executionTime: executionTime
                    )
                )
            }
    }
    
    private func fetchHTML(from url: URL, headers: [String: String]?, timeout: Int?) -> EventLoopFuture<String> {
        let promise = eventLoop.makePromise(of: String.self)
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add custom headers if provided
        headers?.forEach { key, value in
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        // Set timeout if provided
        if let timeout = timeout {
            request.timeoutInterval = TimeInterval(timeout)
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                promise.fail(error)
                return
            }
            
            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                promise.fail(ScraperError.invalidResponse)
                return
            }
            
            promise.succeed(html)
        }
        
        task.resume()
        
        return promise.futureResult
    }
    
    private func extractData(from html: String, selectors: [String]) throws -> [String: [String]] {
        let document = try SwiftSoup.parse(html)
        
        var result: [String: [String]] = [:]
        
        for selector in selectors {
            let elements = try document.select(selector)
            result[selector] = try elements.map { try $0.text() }
        }
        
        return result
    }
}

enum ScraperError: Error {
    case invalidURL
    case invalidResponse
    case parsingError
}