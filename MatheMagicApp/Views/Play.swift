import SwiftUI

struct Play: View {
    @ObservedObject var gameModelView = GameModelView.shared

    var body: some View {
        HStack(alignment: .top) {
            VStack(spacing: 0) {
                // Top bar with Back button and Score display
                HStack(alignment: .top) {
                    Button {
                        gameModelView.reset()
                    } label: {
                        Label("Back", systemImage: "chevron.backward")
                            .labelStyle(.iconOnly)
                    }
                    .offset(x: -23)

                    VStack {
                        Text(String(format: "%02d", gameModelView.score))
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

                // Display elapsed game time and Pause/Play button
                HStack {
                    // Replace the progress view (which used timeLeft) with elapsed time text.
                    Text("Elapsed Time: \(gameModelView.clockTime) s")
                        .font(.headline)
                        .accessibilityLabel(Text("Elapsed time"))
                        .accessibilityValue(Text("\(gameModelView.clockTime) seconds"))
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
