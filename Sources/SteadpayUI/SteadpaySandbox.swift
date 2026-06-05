import SwiftUI
import Steadpay

public struct SteadpaySandbox<Content: View>: View {
    private let lockoutScreen: ((@escaping () -> Void, Entitlements?) -> AnyView)?
    private let warningBanner: ((@escaping () -> Void, @escaping () -> Void) -> AnyView)?
    private let content: Content

    private let onLockout: (() -> Void)?
    private let onWarning: (() -> Void)?
    private let onActive: (() -> Void)?
    private let onError: ((Error) -> Void)?

    @StateObject private var model = SandboxViewModel()

    public init(
        onLockout: (() -> Void)? = nil,
        onWarning: (() -> Void)? = nil,
        onActive: (() -> Void)? = nil,
        onError: ((Error) -> Void)? = nil,
        lockoutScreen: ((@escaping () -> Void, Entitlements?) -> AnyView)? = nil,
        warningBanner: ((@escaping () -> Void, @escaping () -> Void) -> AnyView)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.onLockout = onLockout
        self.onWarning = onWarning
        self.onActive = onActive
        self.onError = onError
        self.lockoutScreen = lockoutScreen
        self.warningBanner = warningBanner
        self.content = content()
    }

    public var body: some View {
        // Update model callbacks on every body eval (non-@Published, no rebuild triggered)
        model.onLockout = onLockout
        model.onWarning = onWarning
        model.onActive = onActive
        model.onError = onError

        return ZStack(alignment: .bottomTrailing) {
            gateContent
            devBadge
        }
        .sheet(isPresented: $model.isPanelOpen) {
            sheetContent
                .presentationDetents([.fraction(0.4)])
        }
    }

    @ViewBuilder
    private var gateContent: some View {
        if model.currentStatus == .lockout {
            if let builder = lockoutScreen {
                builder({}, nil)
            } else {
                LockoutScreen(poweredByWatermark: true, onTriggerCardUpdate: {})
            }
        } else {
            ZStack(alignment: .top) {
                content
                if model.currentStatus == .warning && !model.isDismissed {
                    if let builder = warningBanner {
                        builder({}, model.dismissWarning)
                    } else {
                        WarningBanner(onTriggerCardUpdate: {}, onDismiss: model.dismissWarning)
                    }
                }
            }
        }
    }

    private var devBadge: some View {
        Button {
            model.isPanelOpen = true
        } label: {
            Text("DEV")
                .font(.system(size: 11, design: .monospaced).weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 64, height: 28)
                .background(Color(red: 0.10, green: 0.10, blue: 0.18))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
        .padding(.bottom, 16)
        .padding(.trailing, 16)
        .accessibilityIdentifier("sandbox-dev-badge")
    }

    private var sheetContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("STEADPAY SANDBOX")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .kerning(1)
                Spacer()
                Text(model.currentStatus.rawValue)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                ForEach([SteadpayStatus.active, .warning, .lockout, .error], id: \.self) { s in
                    Button {
                        model.changeStatus(s)
                    } label: {
                        Text(s.rawValue)
                            .font(.system(size: 12,
                                          weight: model.currentStatus == s ? .bold : .medium))
                            .foregroundStyle(model.currentStatus == s ? Color.black : Color.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(model.currentStatus == s ? pillColor(s) : Color.clear)
                            .overlay(Capsule().stroke(Color.secondary.opacity(0.3)))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("sandbox-pill-\(s.rawValue)")
                }
            }

            if !model.log.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(model.log.enumerated()), id: \.offset) { i, entry in
                        Text("\(i == 0 ? "▶" : " ") \(entry)")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(i == 0 ? Color.green : Color.secondary)
                    }
                }
            }

            Text(sandboxRecoveredNote)
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("sandbox-recovered-note")

            Spacer()
        }
        .padding(16)
    }

    private func pillColor(_ status: SteadpayStatus) -> Color {
        switch status {
        case .active: return .green
        case .warning: return .orange
        case .lockout: return .red
        default: return .gray
        }
    }
}

#Preview("Active") {
    SteadpaySandbox { Text("Protected content") }
}
