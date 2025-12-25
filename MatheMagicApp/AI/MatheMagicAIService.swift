//
//  MatheMagicAIService.swift
//  MatheMagicApp
//

import Foundation
import AILib
import os

struct AIEventRunDebug: Sendable, Equatable {
    let runID: String
    let event: String

    let baseURLString: String
    let modelName: String
    let durationMs: Int
    let attempts: Int

    let schemaVersion: Int
    let eventEcho: String?
    let values: [String: String]

    let rawModelContent: String
    let extractedJSON: String

    var formattedValuesText: String {
        var lines: [String] = []
        lines.append("schema_version: \(schemaVersion)")
        lines.append("event_echo: \(eventEcho ?? "<nil>")")

        for key in values.keys.sorted() {
            if let v = values[key] {
                lines.append("\(key): \(v)")
            }
        }
        return lines.joined(separator: "\n")
    }
}

enum MatheMagicAIServiceError: Error, LocalizedError, Sendable {
    case emptyEvent

    var errorDescription: String? {
        switch self {
        case .emptyEvent:
            return "Event text is empty."
        }
    }
}

/// Actor = serialized access + cached contract + production-friendly structure.
actor MatheMagicAIService {
    private let log = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "MatheMagicApp",
        category: "MatheMagicAIService"
    )

    private var endpoint: AIEndpointConfig
    private let templateJSONString: String

    private var cachedContract: AIJSONContract?

    init(
        endpoint: AIEndpointConfig = .current,
        templateJSONString: String = MatheMagicAIContract.templateJSONString
    ) {
        self.endpoint = endpoint
        self.templateJSONString = templateJSONString
    }

    func refreshEndpointFromInfoPlist() {
        endpoint = .current
        log.info("AI endpoint refreshed baseURL=\(self.endpoint.baseURLString, privacy: .public) model=\(self.endpoint.modelName, privacy: .public)")
    }

    func run(event rawEvent: String) async throws -> AIEventRunDebug {
        let event = rawEvent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !event.isEmpty else { throw MatheMagicAIServiceError.emptyEvent }

        try Task.checkCancellation()
        let startedAt = Date()

        let contract: AIJSONContract = try {
            if let cachedContract { return cachedContract }
            let c = try AIJSONContract(templateJSONString: templateJSONString)
            cachedContract = c
            return c
        }()

        let connection = try AILibConnection(
            baseURLString: endpoint.baseURLString,
            modelName: endpoint.modelName,
            options: .deterministic,
            timeout: endpoint.timeout
        )

        let run = try await connection.fillValues(
            event: event,
            contract: contract
        )

        try Task.checkCancellation()

        let durationMs = Int(Date().timeIntervalSince(startedAt) * 1000)
        let last = run.attempts.last

        let clippedRaw = Self.clip(last?.rawModelContent ?? "")
        let clippedExtracted = Self.clip(last?.extractedJSON ?? "")

        return AIEventRunDebug(
            runID: run.runID,
            event: event,
            baseURLString: endpoint.baseURLString,
            modelName: endpoint.modelName,
            durationMs: durationMs,
            attempts: run.attempts.count,
            schemaVersion: run.output.schemaVersion,
            eventEcho: run.output.eventEcho,
            values: run.output.values,
            rawModelContent: clippedRaw,
            extractedJSON: clippedExtracted
        )
    }

    private static func clip(_ s: String, limit: Int = 12_000) -> String {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.count > limit else { return t }
        let idx = t.index(t.startIndex, offsetBy: limit)
        return String(t[..<idx]) + "…"
    }
}
