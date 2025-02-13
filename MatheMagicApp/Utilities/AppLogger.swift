import os

class AppLogger {
    static let shared = AppLogger()
    
    // Common prefix for all messages.
    private let prefix = "⌚️"
    
    // Computed property to retrieve the elapsed game time from GameModelView.
    private var gameTime: Double {
        GameModelView.shared.elapsedTime
    }
        
    // Computed property to format gameTime with two decimal places.
    private var formattedGameTime: String {
        String(format: "%.2f", self.gameTime)
    }
    
    // Logger instances.
    let debugLogger = Logger(subsystem: "com.matheMagic.app", category: "debug")
    let infoLogger = Logger(subsystem: "com.matheMagic.app", category: "info")
    let uiLogger = Logger(subsystem: "com.matheMagic.app", category: "ui")
    let animationLogger = Logger(subsystem: "com.matheMagic.app", category: "animation")
    let warningLogger = Logger(subsystem: "com.matheMagic.app", category: "warning")
    let errorLogger = Logger(subsystem: "com.matheMagic.app", category: "error")
    
    // MARK: - Logging Methods with Elapsed Game Time and Icons

    func debug(_ message: String, _ toPrint: Bool = true) {
        if toPrint {
            self.debugLogger.debug("\(self.prefix)\(self.formattedGameTime) 🔍 \(message)")
        }
    }
    
    func info(_ message: String, _ toPrint: Bool = true) {
        if toPrint {
            self.infoLogger.info("\(self.prefix)\(self.formattedGameTime) ℹ️ \(message)")
        }
    }
    
    func ui(_ message: String, _ toPrint: Bool = true) {
        if toPrint {
            self.uiLogger.debug("\(self.prefix)\(self.formattedGameTime) 🎯 \(message)")
        }
    }
    
    func animation(_ message: String, _ toPrint: Bool = true) {
        if toPrint {
            self.animationLogger.debug("\(self.prefix)\(self.formattedGameTime) ✨ \(message)")
        }
    }
    
    func warning(_ message: String, _ toPrint: Bool = true) {
        if toPrint {
            self.warningLogger.notice("\(self.prefix)\(self.formattedGameTime) ⚠️ \(message)")
        }
    }
    
    func error(_ message: String, _ toPrint: Bool = true) {
        if toPrint {
            self.errorLogger.error("\(self.prefix)\(self.formattedGameTime)  ❌ \(message)")
        }
    }
    
    private init() {}
}
