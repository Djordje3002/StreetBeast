import Foundation
import os

final class AnalyticsService {
    static let shared = AnalyticsService()
    
    private let logger = Logger(subsystem: "com.streetbeast.app", category: "analytics")
    
    private init() {}
    
    func track(_ event: String, metadata: [String: String] = [:]) {
        let payload = metadata
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: ", ")
        logger.info("event=\(event, privacy: .public) meta=\(payload, privacy: .public)")
    }
    
    func error(_ context: String, message: String, metadata: [String: String] = [:]) {
        let payload = metadata
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: ", ")
        logger.error("context=\(context, privacy: .public) message=\(message, privacy: .public) meta=\(payload, privacy: .public)")
    }
}
