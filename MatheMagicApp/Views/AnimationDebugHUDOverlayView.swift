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

private struct BulletLineView: View {
    let text: String

    private var showsBullet: Bool {
        // Continuation line emitted by AnimLibS for MatchTransform.
        !text.hasPrefix("->")
    }

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Text(showsBullet ? "•" : " ")
                .font(.caption2)
                .monospaced()
                // Keep alignment stable even when the bullet is "hidden".
                .frame(width: 10, alignment: .leading)

            Text(text)
                .font(.caption2)
                .monospaced()
                // Allow wrapping for long animation names.
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .opacity(0.85)
    }
}

private struct AnimationDebugHUDCardView: View {
    let card: AnimationDebugCard
    let isCurrent: Bool

    private var baseBackgroundColor: Color {
        if card.kind == .transition { return .red }
        return card.hasModifications ? .orange : .gray
    }

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
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)

            Text(card.subtitle)
                .font(.caption2)
                .monospaced()
                .opacity(0.9)
                .lineLimit(1)

            if !card.details.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(card.details.enumerated()), id: \.offset) { item in
                        BulletLineView(text: item.element)
                    }
                }
            }
        }
        .padding(9)
        .frame(width: 340, alignment: .leading)
        .background(baseBackgroundColor)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
