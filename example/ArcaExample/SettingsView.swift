import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            Section("Subscription") {
                LabeledContent("Plan", value: "Growth")
                LabeledContent("Renewal", value: "Jul 1, 2026")
            }
            Section("Account") {
                LabeledContent("Email", value: "demo@arcta.io")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
