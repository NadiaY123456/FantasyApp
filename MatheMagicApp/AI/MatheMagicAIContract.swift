//
//  MatheMagicAIContract.swift
//  MatheMagicApp
//

import Foundation

enum MatheMagicAIContract {
    static let schemaVersion: Int = 1

    static let templateJSONString: String = #"""
    {
      "schemaVersion": 1,
      "title": "MatheMagicEventToAnimation",
      "includeEventEcho": true,
      "eventEchoRequired": false,
      "context": "You help a game character react to a short EVENT typed by the player. Choose a primary action and a mood. Use no_change if EVENT should not change the current state. Use unclear if ambiguous.",
      "fields": [
        {
          "key": "character_action",
          "promptTitle": "Character: Action",
          "context": "Pick the primary physical action the character should take. Keep coherent with character_mood.",
          "required": true,
          "options": [
            { "value": "unclear" },
            { "value": "no_change" },
            { "value": "idle" },
            { "value": "walk" },
            { "value": "run" },
            { "value": "jump" },
            { "value": "wave" }
          ]
        },
        {
          "key": "character_mood",
          "promptTitle": "Character: Mood",
          "context": "Pick an emotional tone coherent with character_action.",
          "required": true,
          "options": [
            { "value": "unclear" },
            { "value": "no_change" },
            { "value": "calm" },
            { "value": "happy" },
            { "value": "angry" },
            { "value": "scared" },
            { "value": "surprised" }
          ]
        }
      ]
    }
    """#
}
