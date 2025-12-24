//
//  ActiveWorkoutView.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 27/01/2025.
//

import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var activeWorkouts: [ActiveWorkout]
    
    private var activeWorkout: ActiveWorkout? {
        activeWorkouts.first
    }
    
    var body: some View {
        NavigationView {
            Group {
                if let workout = activeWorkout {
                    workoutContent(workout: workout)
                } else {
                    emptyState
                }
            }
            .navigationTitle("Active Workout")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if activeWorkout != nil {
                        Button("Finish") {
                            // TODO: Implement finish workout in Phase 3
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func workoutContent(workout: ActiveWorkout) -> some View {
        List {
            // Workout header
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Started: \(workout.startedAt, style: .time)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if let templateName = workout.templateName {
                        Text("Template: \(templateName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Exercises list
            if let entries = workout.entries, !entries.isEmpty {
                ForEach(entries.sorted(by: { $0.order < $1.order }), id: \.id) { entry in
                    Section(header: Text(entry.exerciseName)) {
                        if let sets = entry.sets, !sets.isEmpty {
                            ForEach(sets.sorted(by: { $0.setNumber < $1.setNumber }), id: \.id) { set in
                                SetRowView(set: set)
                            }
                        } else {
                            Text("No sets yet")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }
            } else {
                Section {
                    Text("No exercises added yet")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No Active Workout")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Start a workout to begin tracking")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SetRowView: View {
    @Bindable var set: WorkoutSet
    
    var body: some View {
        HStack {
            // Set number
            Text("Set \(set.setNumber)")
                .font(.headline)
                .frame(width: 60, alignment: .leading)
            
            Spacer()
            
            // Reps field
            VStack(alignment: .leading, spacing: 4) {
                Text("Reps")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Reps", value: $set.reps, format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
            }
            
            // Weight field
            VStack(alignment: .leading, spacing: 4) {
                Text("Weight")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Weight", value: $set.weight, format: .number)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
            }
            
            // Completion toggle
            Button(action: {
                set.completedAt = set.completedAt == nil ? Date() : nil
            }) {
                Image(systemName: set.completedAt != nil ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(set.completedAt != nil ? .green : .gray)
                    .font(.title2)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ActiveWorkoutView()
        .modelContainer(for: [ExerciseTemplate.self, ActiveWorkout.self, WorkoutEntry.self, WorkoutSet.self, WorkoutHistory.self], inMemory: true)
}

