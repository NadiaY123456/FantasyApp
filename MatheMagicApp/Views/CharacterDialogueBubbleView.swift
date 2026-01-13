//
//  CharacterDialogueBubbleView.swift
//  MatheMagicApp
//

import SwiftUI

struct CharacterDialogueBubbleView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.callout)
            .foregroundStyle(.primary)
            .multilineTextAlignment(.leading)
            .lineLimit(6)
            .fixedSize(horizontal: false, vertical: true)
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(.white.opacity(0.25), lineWidth: 1)
            )
            .accessibilityLabel("Character dialogue")
    }
}
