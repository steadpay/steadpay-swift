import SwiftUI
import SteadpayUI

struct HomeView: View {
    @State private var navigateToSettings = false

    var body: some View {
        SteadpaySandbox(
            onLockout: { print("lockout") },
            onWarning: { print("warning") },
            onActive: { print("active") }
        ) {
            ArctaContentView()
        }
        .navigationTitle("Arcta")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: SettingsView(), isActive: $navigateToSettings) {
                    Button {
                        navigateToSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
        }
    }
}
