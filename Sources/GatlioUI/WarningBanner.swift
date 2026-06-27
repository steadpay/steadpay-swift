import SwiftUI
import Gatlio

// No card-update CTA in warning state (#041): warning is only reachable via soft
// decline, where retrying — not re-entering card details — is the resolution path.
public struct WarningBanner: View {
    let message: String
    let onDismiss: () -> Void

    public init(message: String, onDismiss: @escaping () -> Void) {
        self.message = message
        self.onDismiss = onDismiss
    }

    public var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color(red: 0.96, green: 0.62, blue: 0.04))
                .frame(width: 22, height: 22)
                .overlay(
                    Text("!")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.black)
                )

            Text(message)
                .font(.system(size: 13))
                .foregroundColor(Color(white: 0.83))
                .lineLimit(4)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onDismiss) {
                Text("✕")
                    .font(.system(size: 14))
                    .foregroundColor(Color(white: 0.4))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(white: 0.1))
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1),
            alignment: .bottom
        )
    }
}
