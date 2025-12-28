//
//  ExerciseDetailView.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 27/01/2025.
//

import SwiftUI
import Charts
import SwiftData

struct ExerciseDetailView: View {
    let exercise: ExerciseTemplate
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutHistory.completedAt) private var workoutHistory: [WorkoutHistory]
    
    @State private var oneRMProgression: [OneRepMaxDataPoint] = []
    @State private var filteredProgression: [OneRepMaxDataPoint] = []
    @State private var current1RM: Double?
    @State private var selectedPeriod: TimePeriod = .week
    @State private var showingHistory = false
    @State private var selectedDate: Date? = nil
    
    let periods: [TimePeriod] = [.day, .week, .month, .year]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Current 1RM card
                if let current1RM = current1RM {
                    current1RMCard(oneRM: current1RM)
                } else {
                    noDataCard
                }
                
                // Period selector
                if !oneRMProgression.isEmpty {
                    Picker("Time Period", selection: $selectedPeriod) {
                        ForEach(periods, id: \.self) { period in
                            Text(period.shortDisplayName).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: selectedPeriod) { _, _ in
                        filterProgressionByPeriod()
                    }
                    
                    // 1RM Progression Chart
                    progressionChart
                    
                    // Show All History button
                    Button(action: {
                        showingHistory = true
                    }) {
                        HStack {
                            Text("Show All History")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(AppTheme.background)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppTheme.background.opacity(0.7))
                        }
                        .padding()
                        .background(AppTheme.accentPrimary)
                        .cornerRadius(AppTheme.cornerRadiusMedium)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                }
            }
            .padding()
        }
        .background(AppTheme.background)
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            load1RMData()
        }
        .sheet(isPresented: $showingHistory) {
            ExerciseHistoryView(exercise: exercise)
        }
    }
    
    private func current1RMCard(oneRM: Double) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Estimated 1RM")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(String(format: "%.1f", oneRM))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.accentPrimary)
                
                Text("kg")
                    .font(.title3)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            if oneRMProgression.count > 1 {
                let previous1RM = oneRMProgression[oneRMProgression.count - 2].oneRM
                let change = oneRM - previous1RM
                let changePercent = (change / previous1RM) * 100
                
                HStack(spacing: 4) {
                    Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                        .font(.caption)
                        .foregroundColor(change >= 0 ? AppTheme.accentTertiary : AppTheme.gradientOrangeStart)
                    Text(String(format: "%.1f kg (%.1f%%)", abs(change), abs(changePercent)))
                        .font(.caption)
                        .foregroundColor(change >= 0 ? AppTheme.accentTertiary : AppTheme.gradientOrangeStart)
                    Text("from last workout")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppTheme.cardPrimary)
        .cornerRadius(AppTheme.cornerRadiusLarge)
    }
    
    private var noDataCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 32))
                .foregroundColor(AppTheme.textSecondary)
            Text("No 1RM data yet")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
            Text("Complete workouts with this exercise to see your 1RM progression")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppTheme.cardPrimary)
        .cornerRadius(AppTheme.cornerRadiusLarge)
    }
    
    private var progressionChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("1RM Progression")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal)
            
            // Display selected value above chart
            if let selectedDate = selectedDate,
               let selectedPoint = findClosestPoint(to: selectedDate) {
                VStack(spacing: 8) {
                    Text(String(format: "%.1f kg", selectedPoint.oneRM))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.accentPrimary)
                    
                    Text(selectedPoint.date, style: .date)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding()
                .background(AppTheme.cardPrimary)
                .cornerRadius(AppTheme.cornerRadiusMedium)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            
            Chart {
                ForEach(filteredProgression) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("1RM", point.oneRM)
                    )
                    .foregroundStyle(AppTheme.primaryGradient)
                    
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("1RM", point.oneRM)
                    )
                    .foregroundStyle(AppTheme.accentPrimary)
                    .symbolSize(60)
                }
                
                // Cursor line
                if let selectedDate = selectedDate {
                    RuleMark(x: .value("Selected Date", selectedDate))
                        .foregroundStyle(AppTheme.accentPrimary.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                    
                    // Annotation for selected value
                    if let selectedPoint = findClosestPoint(to: selectedDate) {
                        PointMark(
                            x: .value("Date", selectedPoint.date),
                            y: .value("1RM", selectedPoint.oneRM)
                        )
                        .foregroundStyle(AppTheme.accentPrimary)
                        .symbolSize(100)
                    }
                }
            }
            .chartXSelection(value: $selectedDate)
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                        .foregroundStyle(AppTheme.borderSubtle)
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(formatChartDate(date))
                                .foregroundStyle(AppTheme.textSecondary)
                                .font(.caption)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine()
                        .foregroundStyle(AppTheme.borderSubtle)
                    AxisValueLabel()
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .chartBackground { _ in
                AppTheme.background
            }
            .frame(height: 250)
            .padding(.horizontal)
        }
    }
    
    private func load1RMData() {
        oneRMProgression = OneRepMaxCalculator.get1RMProgression(
            for: exercise.name,
            from: workoutHistory
        )
        current1RM = OneRepMaxCalculator.getCurrent1RM(
            for: exercise.name,
            from: workoutHistory
        )
        filterProgressionByPeriod()
    }
    
    private func filterProgressionByPeriod() {
        let calendar = Calendar.current
        let now = Date()
        let dateRange = selectedPeriod.dateRange(endingAt: now, calendar: calendar)
        
        filteredProgression = oneRMProgression.filter { point in
            point.date >= dateRange.start && point.date <= dateRange.end
        }
    }
    
    // Find the closest data point to the selected date
    private func findClosestPoint(to date: Date) -> OneRepMaxDataPoint? {
        guard !filteredProgression.isEmpty else { return nil }
        return filteredProgression.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
    }
    
    private func formatChartDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        switch selectedPeriod {
        case .day:
            formatter.dateFormat = "HH:mm"
        case .week:
            formatter.dateFormat = "MMM d"
        case .month:
            formatter.dateFormat = "MMM d"
        case .year:
            formatter.dateFormat = "MMM"
        case .sixMonths:
            formatter.dateFormat = "MMM"
        }
        return formatter.string(from: date)
    }
    
    private func colorFromHex(_ hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return Color.blue
        }
        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    NavigationView {
        ExerciseDetailView(exercise: ExerciseTemplate(name: "Bench Press", muscleGroups: ["Chest", "Triceps"]))
    }
    .modelContainer(for: [ExerciseTemplate.self, WorkoutHistory.self], inMemory: true)
}

