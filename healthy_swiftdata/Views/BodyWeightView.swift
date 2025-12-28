//
//  BodyWeightView.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 25/12/2025.
//

import SwiftUI
import SwiftData
import HealthKit

struct BodyWeightView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BodyWeightEntry.recordedAt, order: .reverse) private var weightEntries: [BodyWeightEntry]
    @Query private var workoutHistory: [WorkoutHistory]
    
    @State private var showingAddSheet = false
    @State private var entryToEdit: BodyWeightEntry?
    @State private var entryToDelete: BodyWeightEntry?
    @State private var showingDeleteConfirmation = false
    
    // HealthKit data - now using shared ViewModel
    @StateObject private var healthKitViewModel = HealthKitDataViewModel()
    @StateObject private var healthKitManager = HealthKitManager.shared
    
    // Chart navigation
    @State private var selectedMetricForChart: MetricType? = nil
    @State private var showingChart = false
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Health Metrics Section
                    healthMetricsSection
                    
                    // Body Weight Entry History
                    bodyWeightHistorySection
                }
                .padding(.bottom, 20)
            }
            .background(AppTheme.background)
            .navigationTitle("Health Metrics")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        entryToEdit = nil
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                BodyWeightEntryForm(entry: entryToEdit) { weight, unit, date, notes in
                    saveEntry(weight: weight, unit: unit, recordedAt: date, notes: notes)
                }
            }
            .sheet(isPresented: $showingChart) {
                if let metricType = selectedMetricForChart {
                    ChartDetailView(metricType: metricType)
                }
            }
            .alert("Delete Weight Entry", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let entry = entryToDelete {
                        deleteEntry(entry)
                    }
                }
            } message: {
                if entryToDelete != nil {
                    Text("Are you sure you want to delete this weight entry?")
                }
            }
            .refreshable {
                await healthKitViewModel.refreshHealthKitDataAsync()
            }
            .onAppear {
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
        }
    }
    
    private var healthMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Health Metrics")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal, 20)
            
            let columns = [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ]
            
            LazyVGrid(columns: columns, spacing: 16) {
                healthMetricCards
            }
            .padding(.horizontal, 20)
            
            if let error = healthKitViewModel.healthKitError {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(AppTheme.gradientOrangeStart)
                        Text("HealthKit Access")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    Text(error)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(AppTheme.textSecondary)
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
    
    private var healthMetricCards: some View {
        Group {
            // Body Weight
            if let currentWeight = weightEntries.first {
                MetricCard(
                    icon: "scalemass",
                    value: "\(String(format: "%.1f", currentWeight.weight)) \(currentWeight.unit)",
                    label: "Body Weight",
                    trend: MetricsCalculator.bodyWeightTrend(
                        current: currentWeight,
                        previous: weightEntries.count > 1 ? weightEntries[1] : nil
                    ),
                    color: .purple,
                    onTap: {
                        selectedMetricForChart = .bodyWeight
                        showingChart = true
                    }
                )
            } else {
                MetricCard(
                    icon: "scalemass",
                    value: "—",
                    label: "Body Weight",
                    trend: nil,
                    color: .purple,
                    onTap: {
                        entryToEdit = nil
                        showingAddSheet = true
                    }
                )
            }
            
            // Total Workouts
            MetricCard(
                icon: "figure.strengthtraining.traditional",
                value: "\(MetricsCalculator.totalWorkouts(workoutHistory))",
                label: "Total Workouts",
                trend: nil,
                color: .blue,
                onTap: {
                    selectedMetricForChart = .totalWorkouts
                    showingChart = true
                }
            )
            
            // Total Exercise Time
            MetricCard(
                icon: "clock.fill",
                value: MetricsCalculator.formatDuration(MetricsCalculator.totalExerciseTime(workoutHistory)),
                label: "Total Exercise Time",
                trend: nil,
                color: .green,
                onTap: {
                    selectedMetricForChart = .exerciseTime
                    showingChart = true
                }
            )
            
            // Average Duration
            if let avgDuration = MetricsCalculator.averageWorkoutDuration(workoutHistory) {
                MetricCard(
                    icon: "timer",
                    value: MetricsCalculator.formatAverageDuration(avgDuration),
                    label: "Avg Workout Duration",
                    trend: nil,
                    color: .orange,
                    onTap: {
                        selectedMetricForChart = .exerciseTime
                        showingChart = true
                    }
                )
            }
            
            // Workouts This Week
            MetricCard(
                icon: "calendar",
                value: "\(MetricsCalculator.workoutsThisWeek(workoutHistory))",
                label: "Workouts This Week",
                trend: nil,
                color: .red,
                onTap: {
                    selectedMetricForChart = .workoutsThisWeek
                    showingChart = true
                }
            )
            
            // Most Used Exercise
            if let mostUsed = MetricsCalculator.mostUsedExercise(workoutHistory) {
                MetricCard(
                    icon: "star.fill",
                    value: mostUsed,
                    label: "Most Used Exercise",
                    trend: nil,
                    color: .yellow
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
                        color: .red,
                        onTap: {
                            selectedMetricForChart = .heartRate
                            showingChart = true
                        }
                    )
                } else {
                    MetricCard(
                        icon: "heart.fill",
                        value: "—",
                        label: "Heart Rate",
                        trend: nil,
                        color: .red,
                        onTap: {
                            selectedMetricForChart = .heartRate
                            showingChart = true
                        }
                    )
                }
            }
            
            // Step Count (HealthKit)
            if HKHealthStore.isHealthDataAvailable() {
                if healthKitViewModel.isLoadingHealthKit {
                    MetricCard(
                        icon: "figure.walk",
                        value: "...",
                        label: "Steps Today",
                        trend: nil,
                        color: .cyan
                    )
                } else if let stepCount = healthKitViewModel.stepCount {
                    MetricCard(
                        icon: "figure.walk",
                        value: "\(stepCount)",
                        label: "Steps Today",
                        trend: nil,
                        color: .cyan,
                        onTap: {
                            selectedMetricForChart = .stepCount
                            showingChart = true
                        }
                    )
                } else {
                    MetricCard(
                        icon: "figure.walk",
                        value: "—",
                        label: "Steps Today",
                        trend: nil,
                        color: .cyan,
                        onTap: {
                            selectedMetricForChart = .stepCount
                            showingChart = true
                        }
                    )
                }
            }
            
            // Active Energy / Calories (HealthKit)
            if HKHealthStore.isHealthDataAvailable() {
                if healthKitViewModel.isLoadingHealthKit {
                    MetricCard(
                        icon: "flame.fill",
                        value: "...",
                        label: "Calories Today",
                        trend: nil,
                        color: .orange
                    )
                } else if let activeEnergy = healthKitViewModel.activeEnergy {
                    MetricCard(
                        icon: "flame.fill",
                        value: "\(Int(activeEnergy))",
                        label: "Calories Today",
                        trend: nil,
                        color: .orange,
                        onTap: {
                            selectedMetricForChart = .activeEnergy
                            showingChart = true
                        }
                    )
                } else {
                    MetricCard(
                        icon: "flame.fill",
                        value: "—",
                        label: "Calories Today",
                        trend: nil,
                        color: .orange,
                        onTap: {
                            selectedMetricForChart = .activeEnergy
                            showingChart = true
                        }
                    )
                }
            }
        }
    }
    
    private var bodyWeightHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Body Weight History")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal, 20)
            
            if weightEntries.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "scalemass")
                        .font(.system(size: 60))
                        .foregroundColor(AppTheme.textSecondary)
                    Text("No Weight Entries")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Tap + to record your weight")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(weightEntries) { entry in
                        Button(action: {
                            entryToEdit = entry
                            showingAddSheet = true
                        }) {
                            BodyWeightRow(entry: entry)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(AppTheme.cardPrimary)
                        }
                        .buttonStyle(.plain)
                        
                        if entry.id != weightEntries.last?.id {
                            Divider()
                                .padding(.leading, 20)
                        }
                    }
                }
                .background(AppTheme.cardPrimary)
                .cornerRadius(16)
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - HealthKit
    // HealthKit logic has been extracted to HealthKitDataViewModel
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "scalemass")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.textSecondary)
            Text("No Weight Entries")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.textPrimary)
            Text("Tap + to record your weight")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background)
    }
    
    private func saveEntry(weight: Double, unit: String, recordedAt: Date, notes: String?) {
        if let entry = entryToEdit {
            // Update existing entry
            entry.weight = weight
            entry.unit = unit
            entry.recordedAt = recordedAt
            entry.notes = notes
            try? modelContext.save()
            
            // Save to HealthKit
            Task {
                do {
                    try await healthKitManager.saveBodyWeight(weight: weight, unit: unit, date: recordedAt)
                } catch {
                    print("Failed to save body weight to HealthKit: \(error.localizedDescription)")
                }
            }
        } else {
            // Create new entry
            let newEntry = BodyWeightEntry(
                weight: weight,
                unit: unit,
                recordedAt: recordedAt,
                notes: notes
            )
            modelContext.insert(newEntry)
            try? modelContext.save()
            
            // Save to HealthKit
            Task {
                do {
                    try await healthKitManager.saveBodyWeight(weight: weight, unit: unit, date: recordedAt)
                } catch {
                    print("Failed to save body weight to HealthKit: \(error.localizedDescription)")
                }
            }
        }
        entryToEdit = nil
    }
    
    private func deleteEntry(_ entry: BodyWeightEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
        entryToDelete = nil
    }
}

struct BodyWeightRow: View {
    let entry: BodyWeightEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(String(format: "%.1f", entry.weight)) \(entry.unit)")
                    .font(.headline)
                Spacer()
                Text(entry.recordedAt, style: .date)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            HStack {
                Text(entry.recordedAt, style: .time)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                
                if let notes = entry.notes, !notes.isEmpty {
                    Text("•")
                        .foregroundColor(AppTheme.textSecondary)
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    BodyWeightView()
        .modelContainer(for: [BodyWeightEntry.self], inMemory: true)
}

