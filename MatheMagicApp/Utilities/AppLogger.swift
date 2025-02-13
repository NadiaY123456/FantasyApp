import os

class AppLogger {
    static let shared = AppLogger()
    
    // Common prefix for all messages.
    private let prefix = "📱 "
    
    // Logger instances (renamed to avoid conflicts with methods).
    let debugLogger = Logger(subsystem: "com.matheMagic.app", category: "debug")
    let infoLogger = Logger(subsystem: "com.matheMagic.app", category: "info")
    let uiLogger = Logger(subsystem: "com.matheMagic.app", category: "ui")
    let animationLogger = Logger(subsystem: "com.matheMagic.app", category: "animation")
    let warningLogger = Logger(subsystem: "com.matheMagic.app", category: "warning")
    let errorLogger = Logger(subsystem: "com.matheMagic.app", category: "error")
    
    // MARK: - Logging Methods with Conditional Printing
    func debug(_ message: String, _ toPrint: Bool = true) {
        if toPrint {
            debugLogger.debug("\(self.prefix)🔍 \(message)")
        }
    }
    
    func info(_ message: String, _ toPrint: Bool = true) {
        if toPrint {
            infoLogger.info("\(self.prefix)ℹ️ \(message)")
        }
    }
    
    func ui(_ message: String, _ toPrint: Bool = true) {
        if toPrint {
            uiLogger.debug("\(self.prefix)🎯 \(message)")
        }
    }
    
    func animation(_ message: String, _ toPrint: Bool = true) {
        if toPrint {
            animationLogger.debug("\(self.prefix)✨ \(message)")
        }
    }
    
    func warning(_ message: String, _ toPrint: Bool = true) {
        if toPrint {
            warningLogger.notice("\(self.prefix)⚠️ \(message)")
        }
    }
    
    func error(_ message: String, _ toPrint: Bool = true) {
        if toPrint {
            errorLogger.error("\(self.prefix)❌ \(message)")
        }
    }
    
    private init() {}
}
