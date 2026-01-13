//
//  CharacterDialogueState.swift
//  MatheMagicApp
//

import Foundation

struct CharacterDialogueState: Equatable, Sendable {
    let id: UUID
    let text: String
    let isVisible: Bool

    init(id: UUID = UUID(), text: String = "", isVisible: Bool = false) {
        self.id = id
        self.text = text
        self.isVisible = isVisible
    }
}
