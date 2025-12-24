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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Offline-First Workout Tracker")
                    .font(.title)
                    .fontWeight(.bold)
                
                // Active Workout Status
                if let activeWorkout = activeWorkouts.first {
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
