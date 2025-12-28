//
//  ChartDetailView.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 25/12/2025.
//

import SwiftUI
import Charts
import SwiftData

struct ChartDetailView: View {
    let metricType: MetricType
    @Environment(\.modelContext) private var modelContext
    
    @Query private var workoutHistory: [WorkoutHistory]
    @Query(sort: \BodyWeightEntry.recordedAt, order: .reverse) private var weightEntries: [BodyWeightEntry]
    
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var selectedPeriod: TimePeriod = .week
    @State private var chartData: [ChartDataPoint] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var selectedDate: Date? = nil
    
    let periods: [TimePeriod] = [.day, .week, .month, .sixMonths, .year]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                    Color.clear.frame(height: 0)
                        .background(AppTheme.background)
                    // Period selector
                    Picker("Time Period", selection: $selectedPeriod) {
                        ForEach(periods, id: \.self) { period in
                            Text(period.displayName).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    .onChange(of: selectedPeriod) { _, _ in
                        loadChartDataOptimized()
                    }
                    
                    // Chart
                    if isLoading {
                        ProgressView()
                            .frame(height: 300)
                            .padding()
                    } else if let error = errorMessage {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Text(error)
                                .font(.headline)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        .frame(height: 300)
                        .padding()
                    } else if chartData.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.largeTitle)
                                .foregroundColor(AppTheme.textSecondary)
                            Text("No data available")
                                .font(.headline)
                                .foregroundColor(AppTheme.textSecondary)
                            Text("Try selecting a different time period")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        .frame(height: 300)
                        .padding()
                    } else {
                        // Display selected value above chart
                        if let selectedDate = selectedDate,
                           let selectedPoint = findClosestPoint(to: selectedDate) {
                            VStack(spacing: 8) {
                                Text(formatValue(selectedPoint.value))
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
                            ForEach(chartData) { point in
                                if shouldUseBarChart {
                                    BarMark(
                                        x: .value("Date", point.date),
                                        y: .value("Value", point.value)
                                    )
                                    .foregroundStyle(AppTheme.primaryGradient)
                                } else {
                                    LineMark(
                                        x: .value("Date", point.date),
                                        y: .value("Value", point.value)
                                    )
                                    .foregroundStyle(AppTheme.primaryGradient)
                                    
                                    PointMark(
                                        x: .value("Date", point.date),
                                        y: .value("Value", point.value)
                                    )
                                    .foregroundStyle(AppTheme.accentPrimary)
                                    .symbolSize(60)
                                }
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
                                        y: .value("Value", selectedPoint.value)
                                    )
                                    .foregroundStyle(AppTheme.accentPrimary)
                                    .symbolSize(100)
                                }
                            }
                        }
                        .chartXSelection(value: $selectedDate)
                        .chartXAxis {
                            AxisMarks(values: .automatic) { _ in
                                AxisGridLine()
                                    .foregroundStyle(AppTheme.borderSubtle)
                                AxisValueLabel(format: .dateTime.month().day())
                                    .foregroundStyle(AppTheme.textSecondary)
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
                        .frame(height: 300)
                        .padding(.horizontal)
                    }
                    
                    // Summary stats
                    if !chartData.isEmpty {
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Min")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textSecondary)
                                    if let min = chartData.map(\.value).min() {
                                        Text(formatValue(min))
                                            .font(.headline)
                                    }
                                }
                                Spacer()
                                VStack(alignment: .center) {
                                    Text("Average")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textSecondary)
                                    let avg = chartData.map(\.value).reduce(0, +) / Double(chartData.count)
                                    Text(formatValue(avg))
                                        .font(.headline)
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text("Max")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textSecondary)
                                    if let max = chartData.map(\.value).max() {
                                        Text(formatValue(max))
                                            .font(.headline)
                                            .foregroundColor(AppTheme.textPrimary)
                                    }
                                }
                            }
                            .padding()
                            .background(AppTheme.cardPrimary)
                            .cornerRadius(AppTheme.cornerRadiusMedium)
                        }
                        .padding()
                    }
                    
                    // Show All History button
                    NavigationLink(destination: MetricHistoryView(metricType: metricType)) {
                        HStack {
                            Text("Show All History")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(AppTheme.accentPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        .padding()
                        .background(AppTheme.cardPrimary)
                        .cornerRadius(AppTheme.cornerRadiusMedium)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
            }
        }
        .background(AppTheme.background)
        .navigationTitle(metricType.displayName)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadChartDataOptimized()
        }
        .onChange(of: weightEntries) { _, _ in
            // Reload chart when weight entries change
            if metricType == .bodyWeight {
                loadChartDataOptimized()
            }
        }
        .onChange(of: workoutHistory) { _, _ in
            // Reload chart when workout history changes
            if metricType == .totalWorkouts || metricType == .exerciseTime || metricType == .workoutsThisWeek {
                loadChartDataOptimized()
            }
        }
    }
    
    // Determine if this metric should use a bar chart (for discrete/count data)
    private var shouldUseBarChart: Bool {
        switch metricType {
        case .totalWorkouts, .workoutsThisWeek, .stepCount:
            return true // Discrete counts - use bar charts
        case .bodyWeight, .exerciseTime, .heartRate, .activeEnergy, .average1RM:
            return false // Continuous data - use line charts
        }
    }
    
    // Optimized loading - load local data immediately, HealthKit data async
    private func loadChartDataOptimized() {
        // Load local data immediately (synchronous)
        switch metricType {
        case .totalWorkouts, .exerciseTime, .workoutsThisWeek:
            chartData = loadLocalData()
            isLoading = false
            // No async needed for local data
            
        case .bodyWeight:
            // Use all body weight entries as individual data points (no aggregation)
            chartData = weightEntries.map { entry in
                ChartDataPoint(date: entry.recordedAt, value: entry.weight)
            }.sorted { $0.date < $1.date }
            isLoading = false
            
        case .average1RM:
            // Calculate average 1RM over time
            chartData = loadAverage1RMData()
            isLoading = false
            
        case .heartRate, .stepCount, .activeEnergy:
            // HealthKit data needs async loading
            isLoading = true
            Task {
                await loadHealthKitData()
            }
        }
    }
    
    private func loadLocalData() -> [ChartDataPoint] {
        switch metricType {
        case .totalWorkouts:
            return ChartDataProcessor.aggregateWorkouts(history: workoutHistory, period: selectedPeriod)
        case .exerciseTime:
            return ChartDataProcessor.aggregateExerciseTime(history: workoutHistory, period: selectedPeriod)
        case .workoutsThisWeek:
            return ChartDataProcessor.aggregateWorkoutsThisWeek(history: workoutHistory, period: selectedPeriod)
        default:
            return []
        }
    }
    
    private func loadAverage1RMData() -> [ChartDataPoint] {
        // Calculate average 1RM over time based on selected period
        let calendar = Calendar.current
        let now = Date()
        var chartData: [ChartDataPoint] = []
        
        // Get all unique exercises
        var uniqueExercises = Set<String>()
        for workout in workoutHistory {
            guard let entries = workout.entries else { continue }
            for entry in entries {
                uniqueExercises.insert(entry.exerciseName)
            }
        }
        
        // Calculate based on selected period
        switch selectedPeriod {
        case .day:
            // Daily data for last 30 days
            for dayOffset in 0..<30 {
                guard let dayStart = calendar.date(byAdding: .day, value: -dayOffset, to: now),
                      let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
                    continue
                }
                let dayWorkouts = workoutHistory.filter { workout in
                    workout.completedAt >= dayStart && workout.completedAt < dayEnd
                }
                if let avg1RM = MetricsCalculator.average1RM(from: dayWorkouts) {
                    chartData.append(ChartDataPoint(date: dayStart, value: avg1RM))
                }
            }
        case .week:
            // Weekly data for last 12 weeks
            for weekOffset in 0..<12 {
                guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now),
                      let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
                    continue
                }
                let weekWorkouts = workoutHistory.filter { workout in
                    workout.completedAt >= weekStart && workout.completedAt < weekEnd
                }
                if let avg1RM = MetricsCalculator.average1RM(from: weekWorkouts) {
                    chartData.append(ChartDataPoint(date: weekStart, value: avg1RM))
                }
            }
        case .month, .sixMonths, .year:
            // Monthly data
            for monthOffset in 0..<12 {
                guard let monthStart = calendar.date(byAdding: .month, value: -monthOffset, to: now),
                      let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
                    continue
                }
                let monthWorkouts = workoutHistory.filter { workout in
                    workout.completedAt >= monthStart && workout.completedAt < monthEnd
                }
                if let avg1RM = MetricsCalculator.average1RM(from: monthWorkouts) {
                    chartData.append(ChartDataPoint(date: monthStart, value: avg1RM))
                }
            }
        }
        
        return chartData.sorted { $0.date < $1.date }
    }
    
    private func loadHealthKitData() async {
        do {
            let data: [ChartDataPoint]
            let dateRange = selectedPeriod.dateRange()
            
            switch metricType {
            case .heartRate:
                let hkData = try await healthKitManager.getHeartRateData(from: dateRange.start, to: dateRange.end)
                data = ChartDataProcessor.processHeartRateData(hkData)
                
            case .stepCount:
                let hkData = try await healthKitManager.getStepCountData(from: dateRange.start, to: dateRange.end)
                data = ChartDataProcessor.processStepCountData(hkData)
                
            case .activeEnergy:
                // Simplified - would need proper date range method
                if let energy = try? await healthKitManager.getTodayActiveEnergy() {
                    data = [ChartDataPoint(date: Date(), value: energy)]
                } else {
                    data = []
                }
                
            default:
                data = []
            }
            
            await MainActor.run {
                self.chartData = data
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load chart data: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    private func loadChartData() {
        loadChartDataOptimized()
    }
    
    // Find the closest data point to the selected date
    private func findClosestPoint(to date: Date) -> ChartDataPoint? {
        guard !chartData.isEmpty else { return nil }
        return chartData.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
    }
    
    private func formatValue(_ value: Double) -> String {
        switch metricType {
        case .totalWorkouts, .workoutsThisWeek:
            return "\(Int(value))"
        case .bodyWeight, .average1RM:
            return String(format: "%.1f kg", value)
        case .exerciseTime:
            return String(format: "%.0f min", value)
        case .heartRate:
            return "\(Int(value)) bpm"
        case .stepCount:
            return "\(Int(value))"
        case .activeEnergy:
            return "\(Int(value)) kcal"
        }
    }
}

extension MetricType {
    var color: Color {
        switch self {
        case .totalWorkouts:
            return .blue
        case .bodyWeight:
            return .purple
        case .exerciseTime:
            return .green
        case .workoutsThisWeek:
            return .red
        case .heartRate:
            return .red
        case .stepCount:
            return .cyan
        case .activeEnergy:
            return .orange
        case .average1RM:
            return AppTheme.accentPrimary
        }
    }
}

