//
//  MatheMagicAIContract.swift
//  MatheMagicApp
//

import Foundation

enum MatheMagicAIContract {
    static let schemaVersion: Int = 2

    static var templateJSONString: String {
        let idleEmoteOptions = FlashAIIdleEmoteCatalog.aiContractOptionsJSONArray

        return #"""
        {
          "schemaVersion": \#(schemaVersion),
          "title": "MatheMagicEventToAnimation",
          "includeEventEcho": true,
          "eventEchoRequired": false,
          "context": "You help a game character react to a short EVENT typed by the player by selecting exactly ONE Flash idle emote. Do not choose generic character actions or moods. Use no_change if no idle emote reaction is needed. Use unclear if ambiguous.",
          "fields": [
            {
              "key": "\#(FlashAIIdleEmoteCatalog.aiContractFieldKey)",
              "promptTitle": "Flash: Idle Emote",
              "context": "Pick the single best idle emote reaction for the EVENT (if any). Use the option labels/meanings to map intent (e.g., greeting / acknowledgement / respect -> Salute). Example: \"dragon riders are flying overhead\" => Salute. Use no_change if no emote is needed. Use unclear if ambiguous.",
              "required": true,
              "options": [
                \#(idleEmoteOptions)
              ]
            }
          ]
        }
        """#
    }
}
