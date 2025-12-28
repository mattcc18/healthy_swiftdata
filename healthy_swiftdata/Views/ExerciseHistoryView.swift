//
//  ExerciseHistoryView.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 27/01/2025.
//

import SwiftUI
import SwiftData

struct ExerciseHistoryView: View {
    let exercise: ExerciseTemplate
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutHistory.completedAt, order: .reverse) private var workoutHistory: [WorkoutHistory]
    @Environment(\.dismiss) private var dismiss
    
    private var exerciseWorkouts: [(WorkoutHistory, WorkoutEntry)] {
        var results: [(WorkoutHistory, WorkoutEntry)] = []
        
        for workout in workoutHistory {
            guard let entries = workout.entries else { continue }
            for entry in entries where entry.exerciseName == exercise.name {
                results.append((workout, entry))
            }
        }
        
        return results
    }
    
    var body: some View {
        NavigationStack {
            List {
                if exerciseWorkouts.isEmpty {
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.largeTitle)
                                .foregroundColor(AppTheme.textSecondary)
                            Text("No history yet")
                                .font(.headline)
                                .foregroundColor(AppTheme.textPrimary)
                            Text("Complete workouts with this exercise to see your history")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .listRowBackground(AppTheme.cardPrimary)
                } else {
                    ForEach(Array(exerciseWorkouts.enumerated()), id: \.offset) { index, workoutEntry in
                        let (workout, entry) = workoutEntry
                        Section {
                            // Workout date
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(workout.completedAt, style: .date)
                                        .font(.headline)
                                        .foregroundColor(AppTheme.textPrimary)
                                    if let duration = workout.durationSeconds {
                                        Text("Duration: \(formatDuration(duration))")
                                            .font(.caption)
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                            
                            // Sets
                            if let sets = entry.sets, !sets.isEmpty {
                                ForEach(Array(sets.enumerated()), id: \.offset) { setIndex, set in
                                    HStack {
                                        Text("Set \(setIndex + 1)")
                                            .font(.subheadline)
                                            .foregroundColor(AppTheme.textSecondary)
                                            .frame(width: 50, alignment: .leading)
                                        
                                        Spacer()
                                        
                                        if let weight = set.weight {
                                            Text("\(String(format: "%.1f", weight)) kg")
                                                .font(.subheadline)
                                                .foregroundColor(AppTheme.textPrimary)
                                        }
                                        
                                        if let reps = set.reps {
                                            Text("× \(reps)")
                                                .font(.subheadline)
                                                .foregroundColor(AppTheme.textSecondary)
                                        }
                                        
                                        if let oneRM = set.weight, let reps = set.reps {
                                            let estimated1RM = OneRepMaxCalculator.calculate1RM(weight: oneRM, reps: reps)
                                            Text("(1RM: \(String(format: "%.1f", estimated1RM)) kg)")
                                                .font(.caption)
                                                .foregroundColor(AppTheme.accentPrimary)
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                        .listRowBackground(AppTheme.cardPrimary)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .navigationTitle("Exercise History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.accentPrimary)
                }
            }
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}


