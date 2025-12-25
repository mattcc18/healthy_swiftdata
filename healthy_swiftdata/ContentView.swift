//
//  ContentView.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 24/12/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var activeWorkouts: [ActiveWorkout]
    @Query private var workoutHistory: [WorkoutHistory]
    @Query private var exerciseTemplates: [ExerciseTemplate]
    @Query(sort: \BodyWeightEntry.recordedAt, order: .reverse) private var weightEntries: [BodyWeightEntry]
    
    @Binding var selectedTab: Int
    @State private var showingResumePrompt = false
    @State private var hasCheckedForResume = false
    @State private var showingDiscardConfirmation = false
    
    private var activeWorkout: ActiveWorkout? {
        activeWorkouts.first
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Offline-First Workout Tracker")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    // Active Workout Status
                    if let activeWorkout = activeWorkout {
                        Button(action: {
                            selectedTab = 1 // Switch to Active Workout tab
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Active Workout")
                                        .font(.headline)
                                    Spacer()
                                    Image(systemName: "circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                }
                                Text("Started: \(activeWorkout.startedAt, style: .relative)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("Exercises: \(activeWorkout.entries?.count ?? 0)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button(action: {
                            startNewWorkout()
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Start New Workout")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                    }
                    
                    // Quick Links
                    VStack(spacing: 12) {
                        Text("Quick Links")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button(action: {
                            selectedTab = 2 // Switch to History tab
                        }) {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.blue)
                                Text("View Workout History")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            selectedTab = 3 // Switch to Exercises tab
                        }) {
                            HStack {
                                Image(systemName: "list.bullet")
                                    .foregroundColor(.blue)
                                Text("Browse Exercises")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            selectedTab = 4 // Switch to Templates tab
                        }) {
                            HStack {
                                Image(systemName: "doc.text")
                                    .foregroundColor(.blue)
                                Text("Browse Templates")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(10)
                    
                    // Body Weight Section
                    if let currentWeight = weightEntries.first {
                        Button(action: {
                            // Navigate to weight history (could add weight tab or sheet)
                            // For now, just show current weight
                        }) {
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Body Weight")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Image(systemName: "scalemass")
                                        .foregroundColor(.purple)
                                }
                                
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text("\(String(format: "%.1f", currentWeight.weight))")
                                        .font(.system(size: 32, weight: .bold))
                                    Text(currentWeight.unit)
                                        .font(.title3)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                if weightEntries.count > 1 {
                                    let previousWeight = weightEntries[1]
                                    let change = currentWeight.weight - previousWeight.weight
                                    let changeText = change >= 0 ? "+\(String(format: "%.1f", change))" : String(format: "%.1f", change)
                                    HStack {
                                        Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                                            .foregroundColor(change >= 0 ? .green : .red)
                                        Text("\(changeText) \(currentWeight.unit) from last entry")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Health Metrics
                    VStack(spacing: 12) {
                        Text("Health Metrics")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        let columns = [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ]
                        
                        LazyVGrid(columns: columns, spacing: 12) {
                            // Total Workouts
                            MetricCard(
                                icon: "figure.strengthtraining.traditional",
                                value: "\(MetricsCalculator.totalWorkouts(workoutHistory))",
                                label: "Total Workouts",
                                trend: nil,
                                color: .blue
                            )
                            
                            // Total Exercise Time
                            MetricCard(
                                icon: "clock.fill",
                                value: MetricsCalculator.formatDuration(MetricsCalculator.totalExerciseTime(workoutHistory)),
                                label: "Total Exercise Time",
                                trend: nil,
                                color: .green
                            )
                            
                            // Average Duration
                            if let avgDuration = MetricsCalculator.averageWorkoutDuration(workoutHistory) {
                                MetricCard(
                                    icon: "timer",
                                    value: MetricsCalculator.formatAverageDuration(avgDuration),
                                    label: "Avg Workout Duration",
                                    trend: nil,
                                    color: .orange
                                )
                            }
                            
                            // Workouts This Week
                            MetricCard(
                                icon: "calendar",
                                value: "\(MetricsCalculator.workoutsThisWeek(workoutHistory))",
                                label: "Workouts This Week",
                                trend: nil,
                                color: .red
                            )
                            
                            // Body Weight Trend
                            if let currentWeight = weightEntries.first {
                                MetricCard(
                                    icon: "scalemass",
                                    value: "\(String(format: "%.1f", currentWeight.weight)) \(currentWeight.unit)",
                                    label: "Body Weight",
                                    trend: MetricsCalculator.bodyWeightTrend(
                                        current: currentWeight,
                                        previous: weightEntries.count > 1 ? weightEntries[1] : nil
                                    ),
                                    color: .purple
                                )
                            }
                            
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
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(10)
                    
                    // Statistics (simplified)
                    VStack(spacing: 12) {
                        Text("Statistics")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        StatRow(label: "Exercises", value: "\(exerciseTemplates.count)")
                        StatRow(label: "Workout History", value: "\(workoutHistory.count)")
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Workout Tracker")
            .onAppear {
                // Seed exercise templates on first launch
                DataSeeder.seedExerciseTemplates(modelContext: modelContext)
                // Seed workout templates on first launch (after exercises are seeded)
                DataSeeder.seedWorkoutTemplates(modelContext: modelContext)
                checkForResume()
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
            .alert("Discard Existing Workout?", isPresented: $showingDiscardConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Discard", role: .destructive) {
                    discardAndStartNewWorkout()
                }
            } message: {
                if let workout = activeWorkout {
                    Text("You have an active workout that started \(workout.startedAt, style: .relative). Starting a new workout will discard it. This cannot be undone.")
                } else {
                    Text("Starting a new workout will discard your existing workout. This cannot be undone.")
                }
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
    
    // MARK: - Start Workout
    
    private func startNewWorkout() {
        // Check if there's an existing active workout
        if activeWorkout != nil {
            // Show discard confirmation
            showingDiscardConfirmation = true
        } else {
            // No existing workout, create new one directly
            createNewWorkout()
        }
    }
    
    private func discardAndStartNewWorkout() {
        // Delete existing workout first
        if let workout = activeWorkout {
            modelContext.delete(workout)
            try? modelContext.save()
        }
        // Then create new workout
        createNewWorkout()
    }
    
    private func createNewWorkout() {
        // Create new ActiveWorkout
        let newWorkout = ActiveWorkout(
            startedAt: Date(),
            templateName: nil,
            notes: nil
        )
        
        // Insert into context and save
        modelContext.insert(newWorkout)
        try? modelContext.save()
        
        // Switch to Active Workout tab
        selectedTab = 1
    }
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
