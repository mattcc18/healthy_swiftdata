//
//  MetricCard.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 25/12/2025.
//

import SwiftUI

struct MetricCard: View {
    let icon: String
    let value: String
    let label: String
    let trend: MetricTrend?
    let color: Color
    
    struct MetricTrend {
        let direction: TrendDirection
        let percentage: Double?
        
        enum TrendDirection {
            case up
            case down
            case neutral
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
                if let trend = trend {
                    HStack(spacing: 4) {
                        Image(systemName: trendIcon(trend.direction))
                            .font(.caption)
                            .foregroundColor(trendColor(trend.direction))
                        if let percentage = trend.percentage {
                            Text("\(Int(percentage))%")
                                .font(.caption)
                                .foregroundColor(trendColor(trend.direction))
                        }
                    }
                }
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func trendIcon(_ direction: MetricTrend.TrendDirection) -> String {
        switch direction {
        case .up:
            return "arrow.up"
        case .down:
            return "arrow.down"
        case .neutral:
            return "minus"
        }
    }
    
    private func trendColor(_ direction: MetricTrend.TrendDirection) -> Color {
        switch direction {
        case .up:
            return .green
        case .down:
            return .red
        case .neutral:
            return .secondary
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        MetricCard(
            icon: "figure.strengthtraining.traditional",
            value: "42",
            label: "Total Workouts",
            trend: nil,
            color: .blue
        )
        
        MetricCard(
            icon: "scalemass",
            value: "75.2 kg",
            label: "Body Weight",
            trend: MetricCard.MetricTrend(direction: .down, percentage: 2.5),
            color: .purple
        )
    }
    .padding()
}

