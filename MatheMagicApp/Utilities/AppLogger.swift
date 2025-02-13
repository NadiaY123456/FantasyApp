import os

class AppLogger {
    static let shared = AppLogger()
    
    // Common prefix as a property
    private let prefix = "📱 "
    
    // Loggers for different categories - these don't need the prefix in their category names
    let debug = Logger(subsystem: "com.matheMagic.app", category: "debug")
    let info = Logger(subsystem: "com.matheMagic.app", category: "info")
    let ui = Logger(subsystem: "com.matheMagic.app", category: "ui")
    let animation = Logger(subsystem: "com.matheMagic.app", category: "animation")
    let warning = Logger(subsystem: "com.matheMagic.app", category: "warning")
    let error = Logger(subsystem: "com.matheMagic.app", category: "error")
    
    // Helper methods with explicit self for prefix
    func debug(_ message: String) {
        debug.debug("\(self.prefix)🔍 \(message)")
    }
    
    func info(_ message: String) {
        info.info("\(self.prefix)ℹ️ \(message)")
    }
    
    func ui(_ message: String) {
        ui.debug("\(self.prefix)🎯 \(message)")
    }
    
    func animation(_ message: String) {
        animation.debug("\(self.prefix)✨ \(message)")
    }
    
    func warning(_ message: String) {
        warning.notice("\(self.prefix)⚠️ \(message)")
    }
    
    func error(_ message: String) {
        error.error("\(self.prefix)❌ \(message)")
    }
    
    private init() {}
}
