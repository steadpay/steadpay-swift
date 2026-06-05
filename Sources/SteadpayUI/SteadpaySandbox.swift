import Foundation
import SwiftUI
import Steadpay

public struct SteadpaySandbox: View {
    private let lockoutScreen: ((@escaping () -> Void, Entitlements?) -> AnyView)?
    private let warningBanner: ((@escaping () -> Void, @escaping () -> Void) -> AnyView)?
    private let content: AnyView

    private let onLockout: (() -> Void)?
    private let onWarning: (() -> Void)?
    private let onActive: (() -> Void)?
    private let onError: ((Error) -> Void)?

    @State private var currentStatus: SteadpayStatus = .active
    @State private var isPanelOpen: Bool = false
    @State private var log: [String] = []
    @State private var lastStatus: SteadpayStatus? = .active

    public init(
        onLockout: (() -> Void)? = nil,
        onWarning: (() -> Void)? = nil,
        onActive: (() -> Void)? = nil,
        onError: ((Error) -> Void)? = nil,
        lockoutScreen: ((@escaping () -> Void, Entitlements?) -> AnyView)? = nil,
        warningBanner: ((@escaping () -> Void, @escaping () -> Void) -> AnyView)? = nil,
        @ViewBuilder content: () -> some View
    ) {
        self.onLockout = onLockout
        self.onWarning = onWarning
        self.onActive = onActive
        self.onError = onError
        self.lockoutScreen = lockoutScreen
        self.warningBanner = warningBanner
        self.content = AnyView(content())
    }

    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            gateContent
            devBadge
        }
        .sheet(isPresented: $isPanelOpen) {
            sheetContent
                .presentationDetents([.fraction(0.4)])
        }
    }

    @ViewBuilder
    private var gateContent: some View {
        if currentStatus == .lockout {
            if let builder = lockoutScreen {
                builder({}, nil)
            } else {
                LockoutScreen(poweredByWatermark: true, onTriggerCardUpdate: {})
            }
        } else {
            ZStack(alignment: .top) {
                content
                if currentStatus == .warning {
                    if let builder = warningBanner {
                        builder({}, {})
                    } else {
                        WarningBanner(onTriggerCardUpdate: {}, onDismiss: {})
                    }
                }
            }
        }
    }

    private var devBadge: some View {
        Button {
            isPanelOpen = true
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
                Text(currentStatus.rawValue)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                ForEach([SteadpayStatus.active, .warning, .lockout, .error], id: \.self) { s in
                    Button {
                        changeStatus(s)
                    } label: {
                        Text(s.rawValue)
                            .font(.system(size: 12, weight: currentStatus == s ? .bold : .medium))
                            .foregroundStyle(currentStatus == s ? Color.black : Color.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(currentStatus == s ? pillColor(s) : Color.clear)
                            .overlay(Capsule().stroke(Color.secondary.opacity(0.3)))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("sandbox-pill-\(s.rawValue)")
                }
            }

            if !log.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(log.enumerated()), id: \.offset) { i, entry in
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

    private func changeStatus(_ next: SteadpayStatus) {
        if next == .error {
            let err = NSError(
                domain: "SteadpaySandbox", code: 0,
                userInfo: [NSLocalizedDescriptionKey: "sandbox_error"]
            )
            onError?(err)
            var newLog = log
            newLog.insert("onError(sandbox_error)", at: 0)
            if newLog.count > 5 { newLog.removeLast() }
            log = newLog
            currentStatus = .error
            lastStatus = .error
            return
        }

        let cbName = computeTransition(lastStatus: lastStatus, newStatus: next, isRecoveryPath: false)
        currentStatus = next
        lastStatus = next

        guard let cbName else { return }
        switch cbName {
        case .onLockout: onLockout?()
        case .onWarning: onWarning?()
        case .onActive: onActive?()
        case .onRecovered: break
        }
        var newLog = log
        newLog.insert("\(cbName)()", at: 0)
        if newLog.count > 5 { newLog.removeLast() }
        log = newLog
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
