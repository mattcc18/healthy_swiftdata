//
//  ExerciseView.swift
//  healthy_swiftdata
//
//  Component for displaying a single exercise in an active workout
//

import SwiftUI
import SwiftData

struct ExerciseView: View {
    let entry: WorkoutEntry
    let workout: ActiveWorkout
    let modelContext: ModelContext
    let restTimerManager: RestTimerManager
    let onAddSet: (WorkoutEntry) -> Void
    let onDeleteHighestSet: (WorkoutEntry) -> Void
    let onDeleteSet: (WorkoutSet) -> Void
    let onSetComplete: (Int?, String, Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Exercise title and headers in a tight group
            VStack(alignment: .leading, spacing: 20) {
                // Exercise title
                Text(entry.exerciseName)
                    .foregroundColor(AppTheme.textSecondary)
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                // Column headers
                HStack {
                    Text("Sets").frame(width: 60, alignment: .leading)
                    Text("Reps").frame(width: 80, alignment: .leading)
                    Text("Weight").frame(width: 80, alignment: .leading)
                    Spacer()
                }
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
                .padding(.horizontal)
            }

            // Sets (NO LIST)
            VStack(spacing: 10) {
                ForEach(entry.sets?.sorted(by: { $0.setNumber < $1.setNumber }) ?? []) { set in
                    SetRowView(
                        set: set,
                        modelContext: modelContext,
                        workout: workout,
                        showLabels: false,
                        onSetComplete: onSetComplete,
                        onDeleteSet: onDeleteSet
                    )
                }
            }
            .padding(.horizontal)

            // Add / Remove buttons
            HStack {
                Button {
                    onAddSet(entry)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(AppTheme.accentPrimary)
                }

                Spacer()

                Button {
                    onDeleteHighestSet(entry)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ExerciseTemplate.self, ActiveWorkout.self, WorkoutEntry.self, WorkoutSet.self,
        configurations: config
    )
    
    // Create sample data
    let workout = ActiveWorkout(startedAt: Date())
    let entry = WorkoutEntry(exerciseName: "Squat", order: 1, isWarmup: false)
    entry.activeWorkout = workout
    
    // Create sample sets
    let set1 = WorkoutSet(setNumber: 1, reps: 5, weight: 100.0, restTime: 90, completedAt: Date())
    set1.workoutEntry = entry
    
    let set2 = WorkoutSet(setNumber: 2, reps: 5, weight: 100.0, restTime: 90, completedAt: Date())
    set2.workoutEntry = entry
    
    let set3 = WorkoutSet(setNumber: 3, reps: 5, weight: 100.0, restTime: 90)
    set3.workoutEntry = entry
    
    entry.sets = [set1, set2, set3]
    
    container.mainContext.insert(workout)
    container.mainContext.insert(entry)
    container.mainContext.insert(set1)
    container.mainContext.insert(set2)
    container.mainContext.insert(set3)
    
    return ExerciseView(
        entry: entry,
        workout: workout,
        modelContext: container.mainContext,
        restTimerManager: RestTimerManager(),
        onAddSet: { _ in },
        onDeleteHighestSet: { _ in },
        onDeleteSet: { _ in },
        onSetComplete: { _, _, _ in }
    )
    .modelContainer(container)
    .background(AppTheme.background)
}

