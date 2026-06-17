import SwiftUI
import Steadpay

public struct LockoutScreen: View {
    let poweredByWatermark: Bool
    let message: String
    let cta: String
    let onTriggerCardUpdate: () -> Void

    public init(poweredByWatermark: Bool, message: String, cta: String, onTriggerCardUpdate: @escaping () -> Void) {
        self.poweredByWatermark = poweredByWatermark
        self.message = message
        self.cta = cta
        self.onTriggerCardUpdate = onTriggerCardUpdate
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                cardIcon
                    .padding(.bottom, 36)

                Text("Payment method declined")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 12)

                Text(message)
                    .font(.system(size: 15))
                    .foregroundColor(Color(white: 0.53))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.bottom, 40)

                Button(action: onTriggerCardUpdate) {
                    Text(cta)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.white)
                        .clipShape(Capsule())
                }

                Spacer()
            }
            .padding(.horizontal, 32)

            if poweredByWatermark {
                VStack {
                    Spacer()
                    Text("Powered by Steadpay")
                        .font(.system(size: 12))
                        .foregroundColor(Color(white: 0.27))
                        .padding(.bottom, 32)
                }
            }
        }
    }

    private var cardIcon: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(white: 0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1.5)
                )
                .frame(width: 64, height: 44)
                .overlay(
                    VStack(alignment: .leading, spacing: 7) {
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 11)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.12))
                            .frame(width: 14, height: 10)
                            .padding(.leading, 10)
                    },
                    alignment: .topLeading
                )

            Circle()
                .fill(Color(red: 0.94, green: 0.27, blue: 0.27))
                .frame(width: 20, height: 20)
                .overlay(Text("✕").font(.system(size: 10, weight: .bold)).foregroundColor(.white))
                .offset(x: 8, y: -8)
        }
    }
}
