import SwiftUI

private let metrics: [(String, String)] = [
    ("MRR", "$12,840"),
    ("Active Users", "1,204"),
    ("Churn Rate", "2.4%"),
    ("Conversions", "8.7%"),
]

private let barRatios: [Double] = [0.4, 0.6, 0.5, 0.8, 0.65, 0.9, 0.75]
private let maxBarHeight: Double = 80

private let events: [(String, String)] = [
    ("New subscriber", "2m ago"),
    ("Plan upgrade", "1h ago"),
    ("Trial started", "3h ago"),
]

struct ArctaContentView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                metricGrid
                barChart
                recentEvents
            }
            .padding(16)
        }
    }

    private var metricGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(metrics, id: \.0) { label, value in
                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color(red: 0.10, green: 0.10, blue: 0.18))
                    Text(label)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var barChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Revenue — last 7 days")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(red: 0.10, green: 0.10, blue: 0.18))
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(barRatios.enumerated()), id: \.offset) { _, ratio in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(red: 0.10, green: 0.10, blue: 0.18))
                        .frame(height: ratio * maxBarHeight)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: maxBarHeight)
        }
    }

    private var recentEvents: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Recent Events")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(red: 0.10, green: 0.10, blue: 0.18))
                .padding(.bottom, 8)
            ForEach(events, id: \.0) { label, time in
                HStack {
                    Text(label).font(.system(size: 14))
                    Spacer()
                    Text(time).font(.system(size: 13)).foregroundStyle(.secondary)
                }
                .padding(.vertical, 10)
                Divider()
            }
        }
    }
}
