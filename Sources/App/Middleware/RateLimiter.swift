import Vapor
import NIO

final class RateLimiter: Middleware {
    let maxRequests: Int
    let per: TimeAmount
    
    private var requestCounts: [String: (count: Int, lastReset: Date)] = [:]
    private let lock = NSLock()
    
    init(maxRequests: Int, per: TimeAmount) {
        self.maxRequests = maxRequests
        self.per = per
    }
    
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        let clientIP = request.remoteAddress?.ipAddress ?? "unknown"
        
        lock.lock()
        defer { lock.unlock() }
        
        let now = Date()
        var requestInfo = requestCounts[clientIP] ?? (count: 0, lastReset: now)
        
        // Reset counter if time period has passed
        // Convert nanoseconds to TimeInterval (Double) for comparison
        let timeIntervalLimit = Double(per.nanoseconds) / 1_000_000_000.0
        if now.timeIntervalSince(requestInfo.lastReset) > timeIntervalLimit {
            requestInfo = (count: 0, lastReset: now)
        }
        
        // Increment counter
        requestInfo.count += 1
        requestCounts[clientIP] = requestInfo
        
        // Check if rate limit exceeded
        if requestInfo.count > maxRequests {
            return request.eventLoop.makeFailedFuture(Abort(.tooManyRequests, reason: "Rate limit exceeded"))
        }
        
        return next.respond(to: request)
    }
}