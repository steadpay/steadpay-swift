import SwiftUI
import Steadpay

public struct WarningBanner: View {
    let onTriggerCardUpdate: () -> Void
    let onDismiss: () -> Void

    public init(onTriggerCardUpdate: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.onTriggerCardUpdate = onTriggerCardUpdate
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

            Text("Please update your payment method to avoid interruption.")
                .font(.system(size: 13))
                .foregroundColor(Color(white: 0.83))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 14) {
                Button(action: onTriggerCardUpdate) {
                    Text("Update now")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                }

                Button(action: onDismiss) {
                    Text("✕")
                        .font(.system(size: 14))
                        .foregroundColor(Color(white: 0.4))
                }
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
