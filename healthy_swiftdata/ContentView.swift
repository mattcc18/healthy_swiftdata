//
//  ContentView.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 24/12/2025.
//

import SwiftUI
import SwiftData
import HealthKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var activeWorkouts: [ActiveWorkout]
    @Query private var workoutHistory: [WorkoutHistory]
    @Query private var exerciseTemplates: [ExerciseTemplate]
    @Query(sort: \BodyWeightEntry.recordedAt, order: .reverse) private var weightEntries: [BodyWeightEntry]
    @Query(sort: \BodyMeasurement.recordedAt, order: .reverse) private var bodyMeasurements: [BodyMeasurement]
    
    @Binding var selectedTab: Int
    @State private var showingResumePrompt = false
    @State private var hasCheckedForResume = false
    
    private var activeWorkout: ActiveWorkout? {
        activeWorkouts.first
    }
    
    // HealthKit data - now managed by ViewModel
    @StateObject private var healthKitViewModel = HealthKitDataViewModel()
    
    // Chart navigation
    @State private var selectedMetricForChart: MetricType? = nil
    
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 15) {
                    headerSection
                    activeWorkoutSection
                    healthMetricsSection
                    healthKitErrorSection
                }
                .padding(.bottom, 20)
            }
            .background(AppTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $selectedMetricForChart) { metricType in
                ChartDetailView(metricType: metricType)
            }
            .refreshable {
                await healthKitViewModel.refreshHealthKitDataAsync()
            }
            .onAppear {
                DataSeeder.seedExerciseTemplates(modelContext: modelContext)
                DataSeeder.seedWorkoutTemplates(modelContext: modelContext)
                checkForResume()
                if healthKitViewModel.shouldRefresh {
                    healthKitViewModel.refreshHealthKitData()
                }
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if oldPhase != .active && newPhase == .active {
                    if healthKitViewModel.shouldRefresh {
                        healthKitViewModel.refreshHealthKitData()
                    }
                }
            }
            .onChange(of: activeWorkouts) { _, _ in
                if !hasCheckedForResume {
                    checkForResume()
                }
            }
            .alert("Resume Workout?", isPresented: $showingResumePrompt) {
                Button("Resume") {
                    resumeWorkout()
                }
                Button("Discard", role: .destructive) {
                    discardWorkout()
                }
            } message: {
                if let workout = activeWorkout {
                    Text("You have an active workout that started \(workout.startedAt, style: .relative). Would you like to resume it or discard it?")
                } else {
                    Text("You have an active workout. Would you like to resume it or discard it?")
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Summary")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
            Text(Date(), style: .date)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    private var activeWorkoutSection: some View {
        Group {
            if let activeWorkout = activeWorkout {
                Button(action: {
                    selectedTab = 1
                }) {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(AppTheme.accentPrimary)
                                .frame(width: 32, height: 32)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading, spacing: 4) {
                        Text("Active Workout")
                                .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            Text("\(activeWorkout.entries?.count ?? 0) exercises")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(AppTheme.textPrimary)
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
                    .background(AppTheme.cardPrimary)
                    .cornerRadius(AppTheme.cornerRadiusLarge)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge)
                            .stroke(AppTheme.borderSubtle, lineWidth: 0.5)
                    )
                    .shadow(color: AppTheme.accentPrimary.opacity(0.05), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var healthMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Body Weight - full width (showing week average)
            if let weekAvgWeight = MetricsCalculator.weeklyAverageBodyWeight(from: weightEntries) {
                MetricCard(
                    icon: "scalemass",
                    value: "\(String(format: "%.1f", weekAvgWeight))",
                    label: "Body Weight",
                    trend: MetricsCalculator.bodyWeightTrend(
                        current: weightEntries.first,
                        previous: weightEntries.count > 1 ? weightEntries[1] : nil
                    ),
                    color: AppTheme.accentPrimary,
                    secondaryValue: "kg",
                    chartData: getBodyWeightChartData(),
                    chartType: .line,
                    span: 2,
                    onTap: {
                        selectedMetricForChart = .bodyWeight
                    }
                )
                .padding(.horizontal, 20)
            } else {
                MetricCard(
                    icon: "scalemass",
                    value: "—",
                    label: "Body Weight",
                    trend: nil,
                    color: AppTheme.accentPrimary,
                    chartData: nil,
                    chartType: .line,
                    span: 2,
                    onTap: {
                        selectedMetricForChart = .bodyWeight
                    }
                )
                .padding(.horizontal, 20)
            }
            
            // Average 1RM - full width
            average1RMCard
                .padding(.horizontal, 20)
            
            // Top Exercises - full width
            TopExercisesMetricCard(topExercises: getTopExercises())
                .padding(.horizontal, 20)
            
            // Other metrics in 2-column grid
            let columns = [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ]
            
            LazyVGrid(columns: columns, spacing: 16) {
                // Body Fat card
                bodyFatCard
                
                healthKitMetricCards
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func getTopExercises() -> [TopExercise] {
        return OneRepMaxCalculator.getTopExercises(from: workoutHistory, exerciseTemplates: exerciseTemplates)
    }
    
    // MARK: - Navy Body Fat Card
    
    private var bodyFatCard: some View {
        let bodyFat = calculateNavyBodyFat()
        
        return MetricCard(
            icon: "figure.arms.open",
            value: bodyFat != nil ? String(format: "%.1f", bodyFat!) : "—",
            label: "Navy Body Fat",
            trend: nil,
            color: AppTheme.accentPrimary,
            secondaryValue: bodyFat != nil ? "%" : nil,
            chartData: nil,
            chartType: .bar
        )
    }
    
    private func calculateNavyBodyFat() -> Double? {
        // Get most recent measurements
        let heightMeasurement = bodyMeasurements.first { $0.measurementType == "height" }
        let neckMeasurement = bodyMeasurements.first { $0.measurementType == "neck" }
        let waistMeasurement = bodyMeasurements.first { $0.measurementType == "waist" }
        
        guard let height = heightMeasurement,
              let neck = neckMeasurement,
              let waist = waistMeasurement else {
            return nil
        }
        
        // Navy body fat formula uses height, neck, and waist (not weight)
        // Use male formula (doesn't require hip)
        return NavyBodyFatCalculator.calculateBodyFat(
            gender: "male",
            height: height.value,
            neck: neck.value,
            waist: waist.value,
            hip: nil,
            heightUnit: height.unit,
            circumferenceUnit: neck.unit // Assume all circumference measurements use same unit
        )
    }
    
    private func getBodyWeightChartData() -> [ChartDataPoint] {
        // Get last 7 days of weight data for week average chart
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        
        // Filter to last week and return as individual data points
        return weightEntries
            .filter { $0.recordedAt >= weekAgo }
            .map { entry in
                ChartDataPoint(date: entry.recordedAt, value: entry.weight)
            }
            .sorted { $0.date < $1.date }
    }
    
    private func getStepCountChartData() -> [ChartDataPoint] {
        // Generate placeholder hourly data for today
        // In a real implementation, this would fetch from HealthKit
        let calendar = Calendar.current
        let now = Date()
        var hourlyData: [ChartDataPoint] = []
        
        for hour in 0..<24 {
            if let hourDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: now) {
                // Placeholder: would use actual HealthKit hourly step data
                hourlyData.append(ChartDataPoint(date: hourDate, value: Double.random(in: 0...1000)))
            }
        }
        
        return hourlyData
    }
    
    private func getWorkoutsChartData() -> [ChartDataPoint] {
        // Get last 7 days of workout data (always return 7 data points)
        let calendar = Calendar.current
        let now = Date()
        var dailyData: [Date: Int] = [:]
        
        for workout in workoutHistory {
            let dayStart = calendar.startOfDay(for: workout.completedAt)
            dailyData[dayStart, default: 0] += 1
        }
        
        // Get last 7 days (in reverse order to sort correctly)
        var chartData: [ChartDataPoint] = []
        for dayOffset in (0..<7).reversed() {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) {
                let dayStart = calendar.startOfDay(for: date)
                let count = dailyData[dayStart] ?? 0
                chartData.append(ChartDataPoint(date: dayStart, value: Double(count)))
            }
        }
        
        return chartData // Already in correct order
    }
    
    private func getWorkoutsThisWeekChartData() -> [ChartDataPoint] {
        // Get last 7 days
        return getWorkoutsChartData()
    }
    
    private func getAverage1RMChartData() -> [ChartDataPoint] {
        // Calculate average 1RM for last 7 days (daily aggregation for week view)
        // Always return 7 data points (one per day)
        let calendar = Calendar.current
        let now = Date()
        var chartData: [ChartDataPoint] = []
        
        // Get last 7 days (in reverse order to sort correctly)
        for dayOffset in (0..<7).reversed() {
            guard let dayStart = calendar.date(byAdding: .day, value: -dayOffset, to: now),
                  let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
                continue
            }
            
            // Get workouts on this day
            let dayWorkouts = workoutHistory.filter { workout in
                workout.completedAt >= dayStart && workout.completedAt < dayEnd
            }
            
            // Calculate average 1RM for this day, or use 0 if no data
            if let avg1RM = MetricsCalculator.average1RM(from: dayWorkouts) {
                chartData.append(ChartDataPoint(date: dayStart, value: avg1RM))
            } else {
                // Add zero for days with no 1RM data
                chartData.append(ChartDataPoint(date: dayStart, value: 0))
            }
        }
        
        return chartData // Already in correct order
    }
    
    private func getWorkoutDurationWeeklyChartData() -> [ChartDataPoint] {
        // Get last 7 days of workout durations (daily data for weekly chart)
        // Always return 7 data points (one per day)
        let calendar = Calendar.current
        let now = Date()
        var chartData: [ChartDataPoint] = []
        
        // Get last 7 days (in reverse order to sort correctly)
        for dayOffset in (0..<7).reversed() {
            guard let dayStart = calendar.date(byAdding: .day, value: -dayOffset, to: now),
                  let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
                continue
            }
            
            // Get workouts on this day
            let dayWorkouts = workoutHistory.filter { workout in
                workout.completedAt >= dayStart && workout.completedAt < dayEnd
            }
            
            // Calculate average duration for this day (in minutes)
            if let avgDuration = MetricsCalculator.averageWorkoutDuration(dayWorkouts) {
                let durationMinutes = Double(avgDuration) / 60.0
                chartData.append(ChartDataPoint(date: dayStart, value: durationMinutes))
            } else {
                // Add zero for days with no workouts
                chartData.append(ChartDataPoint(date: dayStart, value: 0))
            }
        }
        
        return chartData // Already in correct order
    }
    
    private var average1RMCard: some View {
        Group {
            // Average 1RM Increase - always show, even if empty
            if let avg1RMData = MetricsCalculator.average1RMIncrease(from: workoutHistory) {
                MetricCard(
                    icon: "arrow.up.circle.fill",
                    value: String(format: "+%.1f%%", avg1RMData.percentage),
                    label: "Average 1RM Δ",
                    trend: MetricsCalculator.average1RMTrend(from: workoutHistory),
                    color: AppTheme.accentPrimary,
                    chartData: getAverage1RMChartData(),
                    chartType: .line,
                    span: 2,
                    onTap: {
                        selectedMetricForChart = .average1RM
                    }
                )
            } else {
                // Show placeholder when no data available
                MetricCard(
                    icon: "arrow.up.circle.fill",
                    value: "—",
                    label: "Average 1RM Δ",
                    trend: nil,
                    color: AppTheme.accentPrimary,
                    chartData: nil,
                    chartType: .line,
                    span: 2,
                    onTap: {
                        selectedMetricForChart = .average1RM
                    }
                )
            }
        }
    }
    
    private var healthKitMetricCards: some View {
        Group {
            // Average Duration (week average)
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            let weekWorkouts = workoutHistory.filter { $0.completedAt >= weekAgo }
            if let avgDuration = MetricsCalculator.averageWorkoutDuration(weekWorkouts) {
                MetricCard(
                    icon: "timer",
                    value: MetricsCalculator.formatAverageDuration(avgDuration),
                    label: "Avg Duration",
                    trend: nil,
                    color: AppTheme.accentPrimary,
                    chartData: getWorkoutDurationWeeklyChartData(),
                    chartType: .bar,
                    onTap: {
                        selectedMetricForChart = .exerciseTime
                    }
                )
            }
            
            // Workouts This Week (showing count)
            let weekWorkoutsCount = workoutHistory.filter { $0.completedAt >= weekAgo }.count
            MetricCard(
                icon: "calendar",
                value: "\(weekWorkoutsCount)",
                label: "Workouts",
                trend: nil,
                color: AppTheme.accentPrimary,
                chartData: getWorkoutsThisWeekChartData(),
                chartType: .bar,
                onTap: {
                    selectedMetricForChart = .workoutsThisWeek
                }
            )
            
            // Stretching Workouts This Week
            let stretchingCount = MetricsCalculator.stretchingWorkoutsThisWeek(from: workoutHistory)
            MetricCard(
                icon: "figure.flexibility",
                value: "\(stretchingCount)",
                label: "Stretching",
                trend: nil,
                color: Color.pink,
                chartData: MetricsCalculator.stretchingWorkoutsChartData(from: workoutHistory),
                chartType: .bar,
                onTap: {
                    selectedMetricForChart = .workoutsThisWeek
                }
            )
            
            // Most Used Exercise (no chart)
            if let mostUsed = MetricsCalculator.mostUsedExercise(workoutHistory) {
                MetricCard(
                    icon: "star.fill",
                    value: mostUsed,
                    label: "Most Used Exercise",
                    trend: nil,
                    color: AppTheme.accentPrimary,
                    chartData: nil,
                    chartType: .bar
                )
            }
            
            // Heart Rate (HealthKit)
            if HKHealthStore.isHealthDataAvailable() {
                if healthKitViewModel.isLoadingHealthKit {
                    MetricCard(
                        icon: "heart.fill",
                        value: "...",
                        label: "Heart Rate",
                        trend: nil,
                        color: .red
                    )
                } else if let heartRate = healthKitViewModel.heartRate {
                    MetricCard(
                        icon: "heart.fill",
                        value: "\(Int(heartRate))",
                        label: "Heart Rate",
                        trend: nil,
                        color: AppTheme.accentPrimary,
                        onTap: {
                            selectedMetricForChart = .heartRate
                        }
                    )
                } else {
                    MetricCard(
                        icon: "heart.fill",
                        value: "—",
                        label: "Heart Rate",
                        trend: nil,
                        color: AppTheme.accentPrimary,
                        onTap: {
                            selectedMetricForChart = .heartRate
                        }
                    )
                }
            }
            
        }
    }
    
    private var healthKitErrorSection: some View {
        Group {
            if let error = healthKitViewModel.healthKitError {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.orange)
                        Text("HealthKit Access")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    Text(error)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.secondary)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.cardPrimary)
                .cornerRadius(AppTheme.cornerRadiusMedium)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMedium)
                        .stroke(AppTheme.borderSubtle, lineWidth: 0.5)
                )
                .padding(.horizontal, 20)
            }
        }
    }
    
    private func checkForResume() {
        // Only check once on initial app launch
        guard !hasCheckedForResume else { return }
        
        if activeWorkout != nil {
            showingResumePrompt = true
        }
        hasCheckedForResume = true
    }
    
    private func resumeWorkout() {
        // Switch to Active Workout tab, which will automatically load the existing ActiveWorkout via @Query
        selectedTab = 1
    }
    
    private func discardWorkout() {
        if let workout = activeWorkout {
            modelContext.delete(workout)
            try? modelContext.save()
        }
    }
    
    // MARK: - HealthKit
    // HealthKit logic has been extracted to HealthKitDataViewModel
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    ContentView(selectedTab: .constant(0))
        .modelContainer(for: [ExerciseTemplate.self, ActiveWorkout.self, WorkoutEntry.self, WorkoutSet.self, WorkoutHistory.self], inMemory: true)
}
