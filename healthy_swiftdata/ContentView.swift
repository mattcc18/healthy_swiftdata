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
                            Text("Active Workout")
                                .font(.headline)
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
                    Text("No active workout")
                        .foregroundColor(.secondary)
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
