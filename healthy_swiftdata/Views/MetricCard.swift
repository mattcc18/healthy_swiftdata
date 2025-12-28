//
//  MetricCard.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 25/12/2025.
//

import SwiftUI

enum ChartType {
    case bar // For daily/hourly data like steps
    case line // For continuous data over time like weight
}

struct MetricCard: View {
    let icon: String
    let value: String
    let label: String
    let trend: MetricTrend?
    let color: Color
    let onTap: (() -> Void)?
    let secondaryValue: String? // Optional secondary value like "2.51 km"
    let chartData: [ChartDataPoint]? // Optional chart data for mini chart
    let chartType: ChartType // Type of chart to display
    let span: Int // Number of columns to span (1 or 2)
    
    init(icon: String, value: String, label: String, trend: MetricTrend? = nil, color: Color, secondaryValue: String? = nil, chartData: [ChartDataPoint]? = nil, chartType: ChartType = .bar, span: Int = 1, onTap: (() -> Void)? = nil) {
        self.icon = icon
        self.value = value
        self.label = label
        self.trend = trend
        self.color = color
        self.secondaryValue = secondaryValue
        self.chartData = chartData
        self.chartType = chartType
        self.span = span
        self.onTap = onTap
    }
    
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
        let cardContent: AnyView
        
        if span == 2 {
            // Horizontal layout for 2-column cards: value on left, chart on right
            cardContent = AnyView(
                VStack(alignment: .leading, spacing: 12) {
                    // Header with title and chevron
                    HStack(alignment: .top) {
                        Text(label)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Spacer()
                        
                        // Chevron icon in top-right
                        if onTap != nil {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    
                    // Horizontal layout: value on left, chart on right
                    HStack(alignment: .center, spacing: 16) {
                        // Left side: Week Avg label and value
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Week Avg")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(AppTheme.textSecondary)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(value)
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(color)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                
                                if let secondary = secondaryValue {
                                    Text(secondary)
                                        .font(.system(size: 18, weight: .regular))
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Right side: chart (only show if chartData exists)
                        if chartData != nil {
                            miniChart
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                        }
                    }
                }
                .padding(16)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 120)
        .background(AppTheme.cardPrimary)
        .cornerRadius(AppTheme.cornerRadiusLarge)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge)
                .stroke(AppTheme.borderSubtle, lineWidth: 0.5)
        )
                .shadow(color: AppTheme.accentPrimary.opacity(0.05), radius: 8, x: 0, y: 4)
            )
        } else {
            // Vertical layout for single column cards
            cardContent = AnyView(
                VStack(alignment: .leading, spacing: 12) {
                    // Header with title and chevron
                    HStack(alignment: .top) {
                        Text(label)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Spacer()
                        
                        // Chevron icon in top-right
                        if onTap != nil {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    
                    // "Week Avg" label
                    Text("Week Avg")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(AppTheme.textSecondary)
                    
                    // Main value in accent color - reduced spacing
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(value)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(color)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        
                        if let secondary = secondaryValue {
                            Text(secondary)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    .padding(.top, -8) // Reduce spacing between "Week Avg" and value
                    
                    Spacer()
                    
                    // Mini chart at the bottom (only show if chartData exists)
                    if chartData != nil {
                        miniChart
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .aspectRatio(1.0, contentMode: .fit) // Make cards square (1:1 ratio)
                .background(AppTheme.cardPrimary)
                .cornerRadius(AppTheme.cornerRadiusLarge)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge)
                        .stroke(AppTheme.borderSubtle, lineWidth: 0.5)
                )
                .shadow(color: AppTheme.accentPrimary.opacity(0.05), radius: 8, x: 0, y: 4)
            )
        }
        
        return Group {
            if let onTap = onTap {
                Button(action: onTap) {
                    cardContent
                }
                .buttonStyle(.plain)
            } else {
                cardContent
            }
        }
        .modifier(GridSpanModifier(span: span))
    }
    
    private var miniChart: some View {
        VStack(spacing: 6) {
            if let data = chartData, !data.isEmpty {
                // Use actual chart data
                GeometryReader { geometry in
                    if chartType == .line {
                        // Line chart for continuous data
                        ZStack {
                            // Draw line
                            Path { path in
                                let sortedData = data.sorted { $0.date < $1.date }
                                guard !sortedData.isEmpty else { return }
                                
                                let minValue = sortedData.map(\.value).min() ?? 0
                                let maxValue = sortedData.map(\.value).max() ?? 1
                                let valueRange = maxValue - minValue
                                let normalizedRange = valueRange > 0 ? valueRange : 1
                                
                                let width = geometry.size.width
                                let height = geometry.size.height
                                
                                for (index, point) in sortedData.enumerated() {
                                    let x = CGFloat(index) / CGFloat(max(1, sortedData.count - 1)) * width
                                    let normalizedValue = (point.value - minValue) / normalizedRange
                                    let y = height - (normalizedValue * height)
                                    
                                    if index == 0 {
                                        path.move(to: CGPoint(x: x, y: y))
                                    } else {
                                        path.addLine(to: CGPoint(x: x, y: y))
                                    }
                                }
                            }
                            .stroke(AppTheme.accentPrimary.opacity(0.8), lineWidth: 2)
                            
                            // Draw points
                            ForEach(Array(data.enumerated()), id: \.element.id) { index, point in
                                let sortedData = data.sorted { $0.date < $1.date }
                                let minValue = sortedData.map(\.value).min() ?? 0
                                let maxValue = sortedData.map(\.value).max() ?? 1
                                let valueRange = maxValue - minValue
                                let normalizedRange = valueRange > 0 ? valueRange : 1
                                
                                let x = CGFloat(index) / CGFloat(max(1, sortedData.count - 1)) * geometry.size.width
                                let normalizedValue = (point.value - minValue) / normalizedRange
                                let y = geometry.size.height - (normalizedValue * geometry.size.height)
                                
                                Circle()
                                    .fill(AppTheme.accentPrimary)
                                    .frame(width: 3, height: 3)
                                    .position(x: x, y: y)
                            }
                        }
                    } else {
                        // Bar chart for discrete data
                        HStack(alignment: .bottom, spacing: 1) {
                            ForEach(Array(data.enumerated()), id: \.element.id) { _, point in
                                let sortedData = data.sorted { $0.date < $1.date }
                                let minValue = sortedData.map(\.value).min() ?? 0
                                let maxValue = sortedData.map(\.value).max() ?? 1
                                let valueRange = maxValue - minValue
                                let normalizedRange = valueRange > 0 ? valueRange : 1
                                
                                let normalizedValue = (point.value - minValue) / normalizedRange
                                let height = max(2, normalizedValue * geometry.size.height)
                                
                                RoundedRectangle(cornerRadius: 0.5)
                                    .fill(AppTheme.accentPrimary)
                                    .frame(width: max(1, (geometry.size.width - CGFloat(data.count - 1)) / CGFloat(data.count)), height: height)
                            }
                        }
                    }
                }
                .frame(height: 24)
                
                // X-axis labels - show day labels for weekly bar charts
                if chartType == .bar && data.count == 7 {
                    // For weekly bar charts (7 days), show day labels
                    HStack {
                        Text(formatDayLabel(data.first?.date ?? Date()))
                            .font(.system(size: 9, weight: .regular))
                            .foregroundColor(AppTheme.textSecondary.opacity(0.6))
                        Spacer()
                        if data.count >= 4 {
                            Text(formatDayLabel(data[data.count / 2].date))
                                .font(.system(size: 9, weight: .regular))
                                .foregroundColor(AppTheme.textSecondary.opacity(0.6))
                            Spacer()
                        }
                        Text(formatDayLabel(data.last?.date ?? Date()))
                            .font(.system(size: 9, weight: .regular))
                            .foregroundColor(AppTheme.textSecondary.opacity(0.6))
                    }
                } else if chartType == .line && data.count >= 2 {
                    // For line charts, show date labels
                    HStack {
                        Text(formatDate(data.first?.date ?? Date()))
                            .font(.system(size: 9, weight: .regular))
                            .foregroundColor(AppTheme.textSecondary.opacity(0.6))
                        Spacer()
                        Text(formatDate(data.last?.date ?? Date()))
                            .font(.system(size: 9, weight: .regular))
                            .foregroundColor(AppTheme.textSecondary.opacity(0.6))
                    }
                }
            } else {
                // Fallback: show placeholder bars for weekly chart (7 days)
                GeometryReader { geometry in
                    HStack(alignment: .bottom, spacing: 1) {
                        ForEach(0..<7) { day in
                            let normalizedDay = Double(day) / 6.0
                            let baseHeight = 0.3 + (sin(normalizedDay * .pi * 2) + 1) * 0.35
                            let height = max(2, baseHeight * geometry.size.height)
                            
                            RoundedRectangle(cornerRadius: 0.5)
                                .fill(AppTheme.cardTertiary)
                                .frame(width: max(1, (geometry.size.width - 6) / 7), height: height)
                        }
                    }
                }
                .frame(height: 24)
                
                // Show day labels for weekly chart
                let calendar = Calendar.current
                let now = Date()
                HStack {
                    if let firstDay = calendar.date(byAdding: .day, value: -6, to: now) {
                        Text(formatDayLabel(firstDay))
                            .font(.system(size: 9, weight: .regular))
                            .foregroundColor(AppTheme.textSecondary.opacity(0.6))
                    }
                    Spacer()
                    if let middleDay = calendar.date(byAdding: .day, value: -3, to: now) {
                        Text(formatDayLabel(middleDay))
                            .font(.system(size: 9, weight: .regular))
                            .foregroundColor(AppTheme.textSecondary.opacity(0.6))
                    }
                    Spacer()
                    Text(formatDayLabel(now))
                        .font(.system(size: 9, weight: .regular))
                        .foregroundColor(AppTheme.textSecondary.opacity(0.6))
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
    
    private func formatDayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E" // Day abbreviation (Mon, Tue, etc.)
        return formatter.string(from: date)
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
            return AppTheme.accentTertiary
        case .down:
            return AppTheme.gradientOrangeStart
        case .neutral:
            return AppTheme.textSecondary
        }
    }
}

struct GridSpanModifier: ViewModifier {
    let span: Int
    
    func body(content: Content) -> some View {
        if span == 2 {
            content
                .gridCellColumns(2)
                .frame(maxWidth: .infinity)
        } else {
            content
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
            color: AppTheme.accentPrimary
        )
        
        MetricCard(
            icon: "scalemass",
            value: "75.2",
            label: "Body Weight",
            trend: MetricCard.MetricTrend(direction: .down, percentage: 2.5),
            color: AppTheme.gradientCyan,
            secondaryValue: "kg"
        )
    }
    .padding()
    .background(AppTheme.background)
}
