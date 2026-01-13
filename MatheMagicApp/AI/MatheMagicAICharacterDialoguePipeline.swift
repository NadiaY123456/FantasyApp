//
//  MatheMagicAICharacterDialoguePipeline.swift
//  MatheMagicApp
//

import Foundation

actor MatheMagicAICharacterDialoguePipeline {

    enum PipelineError: LocalizedError, Sendable {
        case emptyEvent
        case invalidBaseURL(String)
        case invalidHTTPResponse
        case httpError(statusCode: Int, bodyPreview: String)
        case decodingFailed(String)
        case emptyModelResponse

        var errorDescription: String? {
            switch self {
            case .emptyEvent:
                return "Event text is empty."
            case .invalidBaseURL(let s):
                return "Invalid Ollama base URL: \(s)"
            case .invalidHTTPResponse:
                return "Invalid HTTP response."
            case .httpError(let statusCode, let bodyPreview):
                return "Ollama chat request failed (HTTP \(statusCode)): \(bodyPreview)"
            case .decodingFailed(let details):
                return "Failed to decode Ollama response: \(details)"
            case .emptyModelResponse:
                return "Model returned an empty dialogue response."
            }
        }
    }

    func run(eventText: String) async throws -> String {
        let event = try Self.normalizeEvent(eventText)
        try Task.checkCancellation()

        let baseURLString = MatheMagicAIConfig.ollamaBaseURLString
        let modelName = MatheMagicAIConfig.ollamaModelName
        let timeout = MatheMagicAIConfig.timeout

        guard let baseURL = Self.makeBaseURL(baseURLString) else {
            throw PipelineError.invalidBaseURL(baseURLString)
        }

        let chatURL = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("chat")

        let systemPrompt = """
        You are Flash, a friendly magical character in a kids iPad game called MatheMagic.
        Reply to the player's message with exactly ONE short sentence (max 20 words).
        No quotes. No emojis. No narration or actions. No newlines.
        """

        let payload = ChatRequest(
            model: modelName,
            messages: [
                .init(role: "system", content: systemPrompt),
                .init(role: "user", content: event)
            ],
            stream: false,
            options: .init(
                temperature: 0.3,
                topP: 1.0,
                numPredict: 60
            )
        )

        var request = URLRequest(url: chatURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)
        request.timeoutInterval = timeout

        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        let session = URLSession(configuration: config)

        let (data, response) = try await session.data(for: request)
        try Task.checkCancellation()

        guard let http = response as? HTTPURLResponse else {
            throw PipelineError.invalidHTTPResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            throw PipelineError.httpError(
                statusCode: http.statusCode,
                bodyPreview: Self.previewBody(data)
            )
        }

        let decoded: ChatResponse
        do {
            decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        } catch {
            throw PipelineError.decodingFailed(String(describing: error))
        }

        let raw = decoded.message?.content ?? decoded.response ?? ""
        let cleaned = Self.sanitize(raw)

        guard !cleaned.isEmpty else { throw PipelineError.emptyModelResponse }
        return cleaned
    }

    // MARK: - Models

    private struct ChatRequest: Encodable {
        struct Options: Encodable {
            let temperature: Double?
            let topP: Double?
            let numPredict: Int?

            enum CodingKeys: String, CodingKey {
                case temperature
                case topP = "top_p"
                case numPredict = "num_predict"
            }
        }

        let model: String
        let messages: [ChatMessage]
        let stream: Bool
        let options: Options?
    }

    private struct ChatMessage: Encodable {
        let role: String
        let content: String
    }

    private struct ChatResponse: Decodable {
        struct Message: Decodable {
            let role: String?
            let content: String?
        }

        let message: Message?
        // Defensive: some endpoints return `response` (generate-style)
        let response: String?
    }

    // MARK: - Helpers

    private static func makeBaseURL(_ raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let url = URL(string: trimmed), url.scheme != nil {
            return url
        }
        // Allow "host:port" style values by assuming http://
        return URL(string: "http://" + trimmed)
    }

    private static func normalizeEvent(_ text: String) throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw PipelineError.emptyEvent }

        if trimmed.count > MatheMagicAIConfig.maxEventCharacters {
            return String(trimmed.prefix(MatheMagicAIConfig.maxEventCharacters))
        }
        return trimmed
    }

    private static func sanitize(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        // Strip wrapping quotes if present
        if (s.hasPrefix("\"") && s.hasSuffix("\"")) ||
            (s.hasPrefix("“") && s.hasSuffix("”")) ||
            (s.hasPrefix("‘") && s.hasSuffix("’")) ||
            (s.hasPrefix("'") && s.hasSuffix("'"))
        {
            s = String(s.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Collapse whitespace/newlines to a single space
        let parts = s.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        s = parts.joined(separator: " ")

        // Keep only the first sentence if multiple were returned
        if let end = sentenceTerminatorIndex(in: s) {
            let after = s.index(after: end)
            s = String(s[..<after]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Word cap (safety net)
        let words = s.split(whereSeparator: { $0.isWhitespace })
        if words.count > 20 {
            s = words.prefix(20).map(String.init).joined(separator: " ")
        }

        // Hard cap (bubble fit)
        let limit = 240
        if s.count > limit {
            s = String(s.prefix(limit)).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return s
    }

    private static func sentenceTerminatorIndex(in s: String) -> String.Index? {
        for idx in s.indices {
            let ch = s[idx]
            guard ch == "." || ch == "!" || ch == "?" else { continue }

            let next = s.index(after: idx)
            if next == s.endIndex { return idx }
            if s[next] == " " { return idx }
        }
        return nil
    }

    private static func previewBody(_ data: Data) -> String {
        let s = (String(data: data, encoding: .utf8) ?? "<non-utf8 body: \(data.count) bytes>")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if s.count <= 400 { return s }
        return String(s.prefix(400)) + "…"
    }
}
