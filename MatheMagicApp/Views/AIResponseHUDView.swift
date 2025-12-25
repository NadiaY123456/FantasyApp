//
//  AIResponseHUDView.swift
//  MatheMagicApp
//

import SwiftUI

struct AIResponseHUDView: View {
    let state: AIDebugState

    @State private var showDetails: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text("AI")
                    .font(.headline)

                if state.isRunning {
                    ProgressView()
                        .controlSize(.small)
                }

                Spacer(minLength: 0)
            }

            Text(state.statusText)
                .font(.system(.footnote, design: .monospaced))
                .textSelection(.enabled)
                .lineLimit(4)

            if !state.decodedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(state.decodedText)
                    .font(.system(.footnote, design: .monospaced))
                    .textSelection(.enabled)
                    .lineLimit(10)
            }

            if !state.promptPreview.isEmpty || !state.extractedJSON.isEmpty || !state.rawModelContent.isEmpty {
                DisclosureGroup("Details", isExpanded: $showDetails) {
                    if !state.promptPreview.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Prompt preview")
                                .font(.caption)

                            Text(state.promptPreview)
                                .font(.system(.footnote, design: .monospaced))
                                .textSelection(.enabled)
                        }
                        .padding(.top, 6)
                    }

                    if !state.extractedJSON.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Extracted JSON")
                                .font(.caption)

                            Text(state.extractedJSON)
                                .font(.system(.footnote, design: .monospaced))
                                .textSelection(.enabled)
                        }
                        .padding(.top, 6)
                    }

                    if !state.rawModelContent.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Raw model content")
                                .font(.caption)

                            Text(state.rawModelContent)
                                .font(.system(.footnote, design: .monospaced))
                                .textSelection(.enabled)
                        }
                        .padding(.top, 6)
                    }
                }
                .font(.caption)
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.white.opacity(0.25), lineWidth: 1)
        )
    }
}
