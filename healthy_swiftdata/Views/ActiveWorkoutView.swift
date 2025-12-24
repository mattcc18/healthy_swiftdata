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
    @Query private var exerciseTemplates: [ExerciseTemplate]
    @State private var showingAddExercise = false
    
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
                ToolbarItem(placement: .navigationBarLeading) {
                    if activeWorkout != nil {
                        Button("Add Exercise") {
                            showingAddExercise = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddExercise) {
                AddExerciseSheet(
                    exerciseTemplates: exerciseTemplates,
                    onAddExercise: { exerciseName in
                        addExercise(name: exerciseName, to: activeWorkout!)
                    }
                )
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
                                SetRowView(set: set, modelContext: modelContext)
                            }
                        } else {
                            Text("No sets yet")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        
                        // Add set button
                        Button(action: {
                            addSet(to: entry)
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Set")
                            }
                            .foregroundColor(.blue)
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
    
    // MARK: - Exercise Management
    
    private func addExercise(name: String, to workout: ActiveWorkout) {
        guard !name.isEmpty else { return }
        
        // Determine next order position
        let currentEntries = workout.entries ?? []
        let nextOrder = currentEntries.isEmpty ? 0 : (currentEntries.map { $0.order }.max() ?? -1) + 1
        
        // Create WorkoutEntry with exercise name snapshot
        let entry = WorkoutEntry(
            exerciseName: name,
            order: nextOrder
        )
        entry.activeWorkout = workout
        
        // Add entry to workout
        if workout.entries == nil {
            workout.entries = []
        }
        workout.entries?.append(entry)
        
        // Create a default set for the exercise
        let defaultSet = WorkoutSet(setNumber: 1)
        defaultSet.workoutEntry = entry
        
        if entry.sets == nil {
            entry.sets = []
        }
        entry.sets?.append(defaultSet)
        
        // Insert into context and save
        modelContext.insert(entry)
        modelContext.insert(defaultSet)
        try? modelContext.save()
        
        showingAddExercise = false
    }
    
    private func addSet(to entry: WorkoutEntry) {
        let currentSets = entry.sets ?? []
        let nextSetNumber = currentSets.isEmpty ? 1 : (currentSets.map { $0.setNumber }.max() ?? 0) + 1
        
        let newSet = WorkoutSet(setNumber: nextSetNumber)
        newSet.workoutEntry = entry
        
        if entry.sets == nil {
            entry.sets = []
        }
        entry.sets?.append(newSet)
        
        modelContext.insert(newSet)
        try? modelContext.save()
    }
}

struct SetRowView: View {
    @Bindable var set: WorkoutSet
    let modelContext: ModelContext
    
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
                    .onChange(of: set.reps) { _, _ in
                        try? modelContext.save()
                    }
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
                    .onChange(of: set.weight) { _, _ in
                        try? modelContext.save()
                    }
            }
            
            // Completion toggle
            Button(action: {
                set.completedAt = set.completedAt == nil ? Date() : nil
                try? modelContext.save()
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

// MARK: - Add Exercise Sheet

struct AddExerciseSheet: View {
    let exerciseTemplates: [ExerciseTemplate]
    let onAddExercise: (String) -> Void
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    
    var filteredTemplates: [ExerciseTemplate] {
        if searchText.isEmpty {
            return exerciseTemplates
        } else {
            return exerciseTemplates.filter { template in
                template.name.localizedCaseInsensitiveContains(searchText) ||
                template.muscleGroups.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                if exerciseTemplates.isEmpty {
                    Section {
                        Text("No exercise templates available")
                            .foregroundColor(.secondary)
                    }
                } else {
                    Section(header: Text("Exercise Templates")) {
                        ForEach(filteredTemplates, id: \.id) { template in
                            Button(action: {
                                onAddExercise(template.name)
                                dismiss()
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(template.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        if !template.muscleGroups.isEmpty {
                                            Text(template.muscleGroups.joined(separator: ", "))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ActiveWorkoutView()
        .modelContainer(for: [ExerciseTemplate.self, ActiveWorkout.self, WorkoutEntry.self, WorkoutSet.self, WorkoutHistory.self], inMemory: true)
}

