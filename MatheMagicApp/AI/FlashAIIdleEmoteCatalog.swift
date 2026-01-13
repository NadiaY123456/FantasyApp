//
//  FlashAIIdleEmoteCatalog.swift
//  MatheMagicApp
//

import AnimLib
import Foundation

/// App-side helpers for the AI -> Flash idle emote contract.
/// Uses AnimLib's `FlashAIIdleEmoteOptions.animationNames` as the source-of-truth list.
enum FlashAIIdleEmoteCatalog {

    /// Key used by the AI JSON contract for the chosen idle emote.
    static let aiContractFieldKey: String = "flash_idle_emote"

    /// Special option values the model can select.
    static let optionUnclear: String = "unclear"
    static let optionNoChange: String = "no_change"

    /// Allowed idle animation names (RealityKit/AnimLib animation identifiers).
    static var allowedIdleAnimationNames: [String] {
        FlashAIIdleEmoteOptions.animationNames
    }

    /// Full list of contract option values in order.
    /// NOTE: Option "value" must be [A-Za-z0-9_], so we use sanitized tokens here.
    static var aiContractOptionValues: [String] {
        [optionUnclear, optionNoChange] + allowedIdleAnimationNames.map { contractToken(forAnimationName: $0) }
    }

    /// Returns a validated *real* animation name (or `nil` for no_change/unclear/invalid).
    /// Accepts either:
    /// - the real animation name (with '-') OR
    /// - the sanitized contract token (with '_' instead of '-')
    static func normalizedSuggestion(from rawValue: String?) -> String? {
        guard let rawValue else { return nil }

        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        guard trimmed != optionUnclear, trimmed != optionNoChange else { return nil }

        // If the model returns the real anim name, accept it.
        if allowedIdleAnimationNames.contains(trimmed) {
            return trimmed
        }

        // If the model returns the sanitized token, map back to the real anim name.
        return animationNameByContractToken[trimmed]
    }

    /// Converts an animation name into a contract-safe token: any non [A-Za-z0-9_] becomes "_".
    private static func contractToken(forAnimationName animationName: String) -> String {
        var out = ""
        out.reserveCapacity(animationName.count)

        for scalar in animationName.unicodeScalars {
            if CharacterSet.alphanumerics.contains(scalar) || scalar == "_" {
                out.unicodeScalars.append(scalar)
            } else {
                out.append("_")
            }
        }

        return out
    }

    /// Reverse mapping from contract token -> real animation name.
    private static var animationNameByContractToken: [String: String] {
        var dict: [String: String] = [:]
        for anim in allowedIdleAnimationNames {
            dict[contractToken(forAnimationName: anim)] = anim
        }
        return dict
    }

    private struct OptionDetails {
        let label: String
        let meaning: String
    }

    // Explicit “semantic” mapping for known idle emotes.
    // (Keeps option values the same tokens; only adds metadata shown to the model.)
    private static let idleEmoteDetailsByAnimationName: [String: OptionDetails] = [
        "01011_3_EmotionalR-Salute_M": .init(
            label: "Salute (greeting / acknowledgement / respect / wave / hey / bye)",
            meaning: "Use for greeting, acknowledgement, respect, pride, ceremonies, or impressive flyovers. Example: dragon riders are flying overhead."
        ),
        "01012_1_Emotes-Lose_Turn_Around": .init(
            label: "Turn away (embarrassed / defeated / frustrated)",
            meaning: "Use for negative news, embarrassment, defeat, awkwardness, rejection, or a negative turn-away reaction."
        ),
        "01012_2_Emotes-Ponder": .init(
            label: "Ponder (thinking / puzzled / curious)",
            meaning: "Use when asked question, thinking, analyzing, unsure, or reacting to something puzzling (\"hmm\")."
        )
    ]

    private static var optionDetailsByContractValue: [String: OptionDetails] {
        var dict: [String: OptionDetails] = [
            optionUnclear: .init(
                label: "Unclear",
                meaning: "Ambiguous or insufficient info to confidently choose an emote."
            ),
            optionNoChange: .init(
                label: "No emote",
                meaning: "No idle emote reaction needed; keep current idle."
            )
        ]

        // Ensure every allowed idle emote has *some* label/meaning,
        // so adding new emotes later doesn’t silently degrade the prompt quality.
        for anim in allowedIdleAnimationNames {
            let token = contractToken(forAnimationName: anim)

            if let details = idleEmoteDetailsByAnimationName[anim] {
                dict[token] = details
            } else {
                dict[token] = .init(
                    label: prettifiedFallbackLabel(from: anim),
                    meaning: "Idle emote animation."
                )
            }
        }

        return dict
    }

    /// Pre-formatted JSON objects for the MCQ template `"options"` list.
    /// Produces lines like: `{ "value": "no_change" },`
    static var aiContractOptionsJSONArray: String {
        let detailsByValue = optionDetailsByContractValue

        return aiContractOptionValues
            .map { value in
                optionJSONObject(value: value, details: detailsByValue[value])
            }
            .joined(separator: ",\n                ")
    }

    private static func optionJSONObject(value: String, details: OptionDetails?) -> String {
        let escapedValue = jsonEscaped(value)

        guard let details else {
            return #"{ "value": "\#(escapedValue)" }"#
        }

        let escapedLabel = jsonEscaped(details.label)
        let escapedMeaning = jsonEscaped(details.meaning)

        return #"{ "value": "\#(escapedValue)", "label": "\#(escapedLabel)", "meaning": "\#(escapedMeaning)" }"#
    }

    private static func prettifiedFallbackLabel(from animationName: String) -> String {
        // Try to extract the semantic suffix after the last "-" (common in your names),
        // then replace "_" with spaces.
        let base = animationName.split(separator: "-").last.map(String.init) ?? animationName
        let cleaned = base
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return cleaned.isEmpty ? "Idle emote" : cleaned
    }

    private static func jsonEscaped(_ s: String) -> String {
        s
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }
}
