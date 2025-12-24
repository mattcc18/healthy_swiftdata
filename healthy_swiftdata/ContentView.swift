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
    
    @State private var showingResumePrompt = false
    @State private var shouldNavigateToActiveWorkout = false
    @State private var hasCheckedForResume = false
    @State private var showingStartWorkoutConfirmation = false
    @State private var showingDiscardConfirmation = false
    
    private var activeWorkout: ActiveWorkout? {
        activeWorkouts.first
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Offline-First Workout Tracker")
                    .font(.title)
                    .fontWeight(.bold)
                
                // Active Workout Status
                if let activeWorkout = activeWorkout {
                    NavigationLink(destination: ActiveWorkoutView()) {
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
                
                // Statistics
                VStack(spacing: 12) {
                    StatRow(label: "Exercise Templates", value: "\(exerciseTemplates.count)")
                    StatRow(label: "Workout History", value: "\(workoutHistory.count)")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Workout Tracker")
            .onAppear {
                checkForResume()
            }
            .onChange(of: activeWorkouts) { _, _ in
                if !hasCheckedForResume {
                    checkForResume()
                }
            }
            .background(
                NavigationLink(
                    destination: ActiveWorkoutView(),
                    isActive: $shouldNavigateToActiveWorkout
                ) {
                    EmptyView()
                }
                .hidden()
            )
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
        // Navigate to ActiveWorkoutView, which will automatically load the existing ActiveWorkout via @Query
        shouldNavigateToActiveWorkout = true
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
        
        // Navigate to ActiveWorkoutView
        shouldNavigateToActiveWorkout = true
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
    ContentView()
        .modelContainer(for: [ExerciseTemplate.self, ActiveWorkout.self, WorkoutEntry.self, WorkoutSet.self, WorkoutHistory.self], inMemory: true)
}
