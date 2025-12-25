//
//  MatheMagicAIConfig.swift
//  MatheMagicApp
//

import Foundation

enum MatheMagicAIConfig {

    // MARK: - Defaults (match SwiftAIBaseApp)

    static let defaultOllamaBaseURLString: String = "http://100.93.96.72:11434"
    static let defaultOllamaModelName: String = "mistral-small"

    /// End-to-end request timeout for Ollama (seconds).
    static let defaultTimeoutSeconds: TimeInterval = 90

    /// Clamp to keep misconfiguration from making the UI feel broken.
    static let minTimeoutSeconds: TimeInterval = 5
    static let maxTimeoutSeconds: TimeInterval = 300

    /// Keep prompts bounded (prevents accidental huge requests).
    static let maxEventCharacters: Int = 1_024

    /// Prevent runaway UI memory usage in debug overlays.
    static let maxDebugCharacters: Int = 12_000

    // MARK: - Canonical API (used by AIEndpointConfig / pipeline)

    /// Optional Info.plist override: `OllamaBaseURL` (String)
    static var baseURLString: String {
        infoPlistString("OllamaBaseURL") ?? defaultOllamaBaseURLString
    }

    /// Optional Info.plist override: `OllamaModelName` (String)
    static var modelName: String {
        infoPlistString("OllamaModelName") ?? defaultOllamaModelName
    }

    /// Optional Info.plist override: `OllamaTimeoutSeconds` (Number or String)
    static var timeout: TimeInterval {
        let raw = infoPlistTimeInterval("OllamaTimeoutSeconds") ?? defaultTimeoutSeconds
        return clampTimeoutSeconds(raw)
    }

    // MARK: - Backwards-compatible aliases (keep while migrating call sites)

    static var ollamaBaseURLString: String { baseURLString }
    static var ollamaModelName: String { modelName }

    // MARK: - Diagnostics (safe to log)

    static var diagnosticsSummary: String {
        "OllamaBaseURL=\(baseURLString), OllamaModelName=\(modelName), OllamaTimeoutSeconds=\(timeout)"
    }

    // MARK: - Info.plist helpers

    private static func infoPlistString(_ key: String) -> String? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: key) else { return nil }

        if let s = raw as? String {
            let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }

        // Defensive: if a non-string sneaks in, stringify it.
        let s = String(describing: raw).trimmingCharacters(in: .whitespacesAndNewlines)
        return s.isEmpty ? nil : s
    }

    private static func infoPlistTimeInterval(_ key: String) -> TimeInterval? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: key) else { return nil }

        if let n = raw as? NSNumber {
            return n.doubleValue
        }

        if let s = raw as? String {
            let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            return Double(trimmed)
        }

        return nil
    }

    private static func clampTimeoutSeconds(_ value: TimeInterval) -> TimeInterval {
        min(max(value, minTimeoutSeconds), maxTimeoutSeconds)
    }
}
