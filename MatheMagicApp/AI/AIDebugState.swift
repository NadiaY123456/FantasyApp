//
//  AIDebugState.swift
//  MatheMagicApp
//

import Foundation

struct AIDebugState: Equatable, Sendable {
    var isRunning: Bool = false
    var statusText: String = "AI: idle"
    var lastEventText: String = ""

    var promptPreview: String = ""
    var decodedText: String = ""
    var extractedJSON: String = ""
    var rawModelContent: String = ""
    var latestValues: [String: String] = [:]

    mutating func start(eventText: String) {
        isRunning = true
        statusText = "AI: running…"
        lastEventText = eventText

        promptPreview = ""
        decodedText = ""
        extractedJSON = ""
        rawModelContent = ""
        latestValues = [:]
    }

    mutating func setSuccess(_ result: MatheMagicAIRunResult) {
        isRunning = false
        statusText = result.statusText
        promptPreview = result.promptPreview
        decodedText = result.decodedText
        extractedJSON = result.extractedJSON
        rawModelContent = result.rawModelContent
        latestValues = result.values
    }

    mutating func setFailure(_ error: Error) {
        isRunning = false
        statusText = "AI: FAILED: \(error.localizedDescription)"
    }

    mutating func setCancelled() {
        isRunning = false
        statusText = "AI: cancelled"
    }
}
