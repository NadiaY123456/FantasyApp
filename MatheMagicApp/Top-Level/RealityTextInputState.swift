//
//  RealityTextInputState.swift
//  MatheMagicApp
//

import Foundation

/// Where the submission came from (useful for analytics + future AI “input mode” logic).
enum UserTextInputSource: String, Sendable {
    case sendButton
    case keyboardReturn
}

/// Single submitted text input event (ready to route to an AI pipeline later).
struct UserTextInputEvent: Identifiable, Equatable, Sendable {
    let id: UUID
    let text: String

    /// Seconds since 1970 (safe to pass across concurrency domains).
    let submittedAtUnix: TimeInterval

    let source: UserTextInputSource

    init(
        id: UUID = UUID(),
        text: String,
        submittedAtUnix: TimeInterval = Date().timeIntervalSince1970,
        source: UserTextInputSource
    ) {
        self.id = id
        self.text = text
        self.submittedAtUnix = submittedAtUnix
        self.source = source
    }
}

/// Holds draft text + bounded submission history for the RealityView overlay.
struct RealityTextInputState: Equatable {
    var draft: String = ""
    private(set) var submitted: [UserTextInputEvent] = []

    /// Prevents unbounded growth while still giving you debugging context.
    static let historyLimit: Int = 50

    var lastSubmitted: UserTextInputEvent? { submitted.last }

    var canSubmit: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Submits the current draft (trimmed), appends to history (bounded), clears draft.
    /// - Returns: The created event, or nil if draft is empty/whitespace.
    @discardableResult
    mutating func submitDraft(source: UserTextInputSource) -> UserTextInputEvent? {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let event = UserTextInputEvent(text: trimmed, source: source)
        submitted.append(event)

        if submitted.count > Self.historyLimit {
            submitted.removeFirst(submitted.count - Self.historyLimit)
        }

        draft = ""
        return event
    }

    mutating func clearHistory(keepingCapacity: Bool = true) {
        submitted.removeAll(keepingCapacity: keepingCapacity)
    }
}
