import SwiftUI

struct CustomButtonStyle: ButtonStyle {
    @State private var isPressed: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom("TimesNewRomanPS-BoldMT", size: 40)) // Adjust size as needed
            .foregroundColor(.white)
            .padding()
            .frame(width: 250, height: 100) // Adjust size to fit your layout
            .background(Color(red: 81/255, green: 156/255, blue: 72/255))
            .cornerRadius(30)
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color(red: 60/255, green: 115/255, blue: 53/255), lineWidth: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color(red: 136/255, green: 219/255, blue: 125/255), lineWidth: 6)
            )
            .shadow(color: Color(red: 0/255, green: 100/255, blue: 0/255).opacity(0.5), radius: 10, x: 0, y: 10)
            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 5)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
