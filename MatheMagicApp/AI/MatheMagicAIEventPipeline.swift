//
//  MatheMagicAIEventPipeline.swift
//  MatheMagicApp
//

import AILib
import Foundation

struct MatheMagicAIRunResult: Sendable, Equatable {
    let event: String
    let runID: String
    let durationMs: Int

    let baseURLString: String
    let modelName: String
    let attempts: Int

    let schemaVersion: Int
    let eventEcho: String?
    let values: [String: String]

    let promptPreview: String
    let rawModelContent: String
    let extractedJSON: String
    let decodedText: String
    let statusText: String
}

actor MatheMagicAIEventPipeline {

    enum PipelineError: LocalizedError, Sendable {
        case emptyEvent

        var errorDescription: String? {
            switch self {
            case .emptyEvent:
                return "Event text is empty."
            }
        }
    }

    func run(eventText: String) async throws -> MatheMagicAIRunResult {
        let event = try Self.normalizeEvent(eventText)
        try Task.checkCancellation()

        let startedAt = Date()

        let baseURLString = MatheMagicAIConfig.ollamaBaseURLString
        let modelName = MatheMagicAIConfig.ollamaModelName
        let template = MatheMagicAIContract.templateJSONString

        // “Package as prompt” (debug-friendly; matches SwiftAIBaseApp PromptPreviewModel behavior)
        let promptPreview = ClassifierRunner().buildPromptPreview(
            event: event,
            templateJSONString: template
        )

        let connection = try AILibConnection(
            baseURLString: baseURLString,
            modelName: modelName
        )

        let run = try await connection.fillValues(
            event: event,
            templateJSONString: template
        )

        try Task.checkCancellation()

        let durationMs = Int(Date().timeIntervalSince(startedAt) * 1000)
        let attempts = run.attempts.count

        let last = run.attempts.last
        let raw = String((last?.rawModelContent ?? "").prefix(MatheMagicAIConfig.maxDebugCharacters))
        let extracted = String((last?.extractedJSON ?? "").prefix(MatheMagicAIConfig.maxDebugCharacters))

        let decoded = Self.describe(run.output)

        let runIDString = String(describing: run.runID)

        let status = """
        AI: OK (\(durationMs)ms)
        Attempts: \(attempts)
        Base URL: \(connection.baseURL.absoluteString)
        Model: \(modelName)
        RunID: \(runIDString)
        """

        return MatheMagicAIRunResult(
            event: event,
            runID: runIDString,
            durationMs: durationMs,
            baseURLString: connection.baseURL.absoluteString,
            modelName: modelName,
            attempts: attempts,
            schemaVersion: run.output.schemaVersion,
            eventEcho: run.output.eventEcho,
            values: run.output.values,
            promptPreview: promptPreview,
            rawModelContent: raw,
            extractedJSON: extracted,
            decodedText: decoded,
            statusText: status
        )
    }

    private static func normalizeEvent(_ text: String) throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw PipelineError.emptyEvent }

        if trimmed.count > MatheMagicAIConfig.maxEventCharacters {
            return String(trimmed.prefix(MatheMagicAIConfig.maxEventCharacters))
        }

        return trimmed
    }

    private static func describe(_ output: MCQFilledResponse) -> String {
        var lines: [String] = []
        lines.append("schema_version: \(output.schemaVersion)")
        lines.append("event_echo: \(output.eventEcho ?? "<nil>")")

        for key in output.values.keys.sorted() {
            if let value = output.values[key] {
                lines.append("\(key): \(value)")
            }
        }

        return lines.joined(separator: "\n")
    }
}
