//
//  RealityTextInputOverlayView.swift
//  MatheMagicApp
//

import SwiftUI

/// A reusable text-input bar intended to be overlaid on top of a RealityView.
/// - Binds to `RealityTextInputState` (draft + bounded history).
/// - Emits a typed `UserTextInputEvent` on submit.
/// - Reports focus changes so the parent can disable camera gestures while typing.
struct RealityTextInputOverlayView: View {
    @Binding var input: RealityTextInputState

    var placeholder: String = "Type a message…"
    var onSubmit: (UserTextInputEvent) -> Void
    var onFocusChange: (Bool) -> Void = { _ in }

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            TextField(placeholder, text: $input.draft)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isFocused)
                .submitLabel(.send)
                .onSubmit { submit(source: .keyboardReturn) }
                .onChange(of: isFocused) { newValue in
                    onFocusChange(newValue)
                }

            Button {
                submit(source: .sendButton)
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 16, weight: .semibold))
            }
            .buttonStyle(.borderedProminent)
            .disabled(!input.canSubmit)
            .accessibilityLabel("Send")
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.white.opacity(0.25), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
    }

    private func submit(source: UserTextInputSource) {
        guard let event = input.submitDraft(source: source) else { return }
        onSubmit(event)

        // Dismiss focus so camera gestures resume immediately after sending.
        isFocused = false
        onFocusChange(false)
    }
}
