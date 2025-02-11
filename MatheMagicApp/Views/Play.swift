/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The play screen for single player.
*/

import SwiftUI

struct Play: View {
    @ObservedObject var gameModelView = GameModelView.shared

    
    var body: some View {
        HStack(alignment: .top) {
            VStack(spacing: 0) {
                let progress = Float(gameModelView.timeLeft) / Float(GameModel.gameTime)
                HStack(alignment: .top) {
                    Button {
                        Task {
                        }
                        gameModelView.reset()
                    } label: {
                        Label("Back", systemImage: "chevron.backward")
                            .labelStyle(.iconOnly)
                    }
                    .offset(x: -23)

                    VStack {
                        Text(verbatim: "\(String(format: "%02d", gameModelView.score))")
                            .font(.system(size: 60))
                            .bold()
                            .accessibilityLabel(Text("Score"))
                            .accessibilityValue(Text("\(gameModelView.score)"))
                        Text("score")
                            .font(.system(size: 30))
                            .bold()
                            .accessibilityHidden(true)
                            .offset(y: -5)
                    }
                    .padding(.leading, 0)
                    .padding(.trailing, 60)
                }
                HStack {
                    ProgressView(value: (progress > 1.0 || progress < 0.0) ? 1.0 : progress)
                        .contentShape(.accessibility, Capsule().offset(y: -3))
                        .accessibilityLabel("")
                        .accessibilityValue(Text("\(gameModelView.timeLeft) seconds remaining"))
                        .tint(Color(uiColor: UIColor(red: 242 / 255, green: 68 / 255, blue: 206 / 255, alpha: 1.0)))
                        .padding(.vertical, 30)
                    Button {
                        gameModelView.togglePause()
                    } label: {
                        if gameModelView.isPaused {
                            Label("Play", systemImage: "play.fill")
                                .labelStyle(.iconOnly)
                        } else {
                            Label("Pause", systemImage: "pause.fill")
                                .labelStyle(.iconOnly)
                        }
                    }
                    .padding(.trailing, 12)
                    .padding(.leading, 10)
                }
                .background(
                    .regularMaterial,
                    in: .rect(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: 12,
                        bottomTrailingRadius: 12,
                        topTrailingRadius: 0,
                        style: .continuous
                    )
                )
                .frame(width: 260, height: 70)
                .offset(y: 15)
            }
            .padding(.vertical, 12)
        }
        .frame(width: 260)
    }
}

