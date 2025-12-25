//
//  AnimationDebugHUDOverlayView.swift
//  MatheMagicApp
//

import AnimLib
import SwiftUI

struct AnimationDebugHUDOverlayView: View {
    @EnvironmentObject private var gameModelView: GameModelView

    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            Button(action: { gameModelView.toggleAnimationDebugHUD() }) {
                Text(gameModelView.showAnimationDebugHUD ? "Anim HUD: ON" : "Anim HUD: OFF")
                    .font(.caption2)
                    .monospaced()
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.65))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)

            if gameModelView.showAnimationDebugHUD {
                VStack(alignment: .trailing, spacing: 8) {
                    // Current = last; display newest first.
                    ForEach(gameModelView.animationDebugHUDCards.reversed()) { card in
                        let isCurrent = (card.id == gameModelView.animationDebugHUDCards.last?.id)
                        AnimationDebugHUDCardView(card: card, isCurrent: isCurrent)
                    }
                }
                .allowsHitTesting(false) // cards don't steal gestures from RealityView
            }
        }
    }
}

private struct AnimationDebugHUDCardView: View {
    let card: AnimationDebugCard
    let isCurrent: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Text(isCurrent ? "CURRENT" : "HISTORY")
                    .font(.caption2)
                    .monospaced()
                    .opacity(0.85)

                Spacer(minLength: 8)

                Text(card.kind.rawValue.uppercased())
                    .font(.caption2)
                    .monospaced()
                    .opacity(0.85)
            }

            Text(card.title)
                .font(isCurrent ? .caption : .caption2)
                .monospaced()
                .bold()
                .lineLimit(2)

            Text(card.subtitle)
                .font(.caption2)
                .monospaced()
                .opacity(0.9)
                .lineLimit(2)

            if !card.details.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(card.details, id: \.self) { line in
                        Text("• \(line)")
                            .font(.caption2)
                            .monospaced()
                            .opacity(0.85)
                            .lineLimit(2)
                    }
                }
            }
        }
        .padding(9)
        .frame(width: 340, alignment: .leading)
        .background(.black.opacity(isCurrent ? 0.80 : 0.55))
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .opacity(isCurrent ? 1.0 : 0.78)
    }
}
