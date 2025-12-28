//
//  WorkoutHistoryEditView.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 28/12/2025.
//

import SwiftUI
import SwiftData

struct WorkoutHistoryEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var workout: WorkoutHistory
    
    @State private var showingSaveConfirmation = false
    
    var body: some View {
        List {
            // Workout header (editable)
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Completed: \(workout.completedAt, style: .date)")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    if let duration = workout.durationSeconds {
                        Text("Duration: \(formatDuration(duration))")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    
                    if let templateName = workout.templateName {
                        Text("Template: \(templateName)")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    
                    // Editable workout type
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Workout Type")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        Picker("Workout Type", selection: Binding(
                            get: {
                                workout.workoutType.flatMap { WorkoutType(rawValue: $0) }
                            },
                            set: { newValue in
                                workout.workoutType = newValue?.rawValue
                            }
                        )) {
                            Text("None").tag(nil as WorkoutType?)
                            ForEach(WorkoutType.allCases, id: \.self) { type in
                                HStack {
                                    Circle()
                                        .fill(type.color)
                                        .frame(width: 12, height: 12)
                                    Text(type.displayName)
                                }
                                .tag(type as WorkoutType?)
                            }
                        }
                        .foregroundColor(AppTheme.textPrimary)
                    }
                    
                    // Editable notes
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                        TextField("Add notes...", text: Binding(
                            get: { workout.notes ?? "" },
                            set: { workout.notes = $0.isEmpty ? nil : $0 }
                        ), axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                        .foregroundColor(AppTheme.textPrimary)
                    }
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(AppTheme.cardPrimary)
            
            // Exercises and sets (editable)
            if let entries = workout.entries, !entries.isEmpty {
                ForEach(entries.sorted(by: { $0.order < $1.order }), id: \.id) { entry in
                    Section(header: Text(entry.exerciseName)) {
                        if let sets = entry.sets, !sets.isEmpty {
                            ForEach(sets.sorted(by: { $0.setNumber < $1.setNumber }), id: \.id) { set in
                                EditableSetRow(set: set, modelContext: modelContext)
                            }
                        } else {
                            Text("No sets")
                                .foregroundColor(AppTheme.textSecondary)
                                .font(.caption)
                        }
                        
                        // Exercise notes (editable)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Exercise Notes")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                            TextField("Add notes...", text: Binding(
                                get: { entry.notes ?? "" },
                                set: { entry.notes = $0.isEmpty ? nil : $0 }
                            ), axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(2...4)
                            .foregroundColor(AppTheme.textPrimary)
                        }
                        .padding(.top, 4)
                    }
                    .listRowBackground(AppTheme.cardPrimary)
                }
            } else {
                Section {
                    Text("No exercises")
                        .foregroundColor(AppTheme.textSecondary)
                }
                .listRowBackground(AppTheme.cardPrimary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .listRowBackground(AppTheme.cardPrimary)
        .navigationTitle("Edit Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveWorkout()
                }
            }
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
    
    private func saveWorkout() {
        // Recalculate total volume
        var totalVolume: Double = 0.0
        if let entries = workout.entries {
            for entry in entries {
                if let sets = entry.sets {
                    for set in sets {
                        if let weight = set.weight, let reps = set.reps {
                            totalVolume += weight * Double(reps)
                        }
                    }
                }
            }
        }
        workout.totalVolume = totalVolume > 0 ? totalVolume : nil
        
        // Recalculate duration if needed
        let duration = Int(workout.completedAt.timeIntervalSince(workout.startedAt))
        workout.durationSeconds = duration
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save workout: \(error)")
        }
    }
}

// MARK: - Editable Set Row

struct EditableSetRow: View {
    @Bindable var set: WorkoutSet
    let modelContext: ModelContext
    
    var body: some View {
        HStack {
            // Set number
            Text("Set \(set.setNumber)")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
                .frame(width: 60, alignment: .leading)
            
            Spacer()
            
            // Reps field (editable)
            VStack(alignment: .leading, spacing: 4) {
                Text("Reps")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                TextField("Reps", value: $set.reps, format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                    .background(AppTheme.cardTertiary)
                    .onChange(of: set.reps) { _, _ in
                        try? modelContext.save()
                    }
            }
            
            // Weight field (editable)
            VStack(alignment: .leading, spacing: 4) {
                Text("Weight")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                TextField("Weight", value: $set.weight, format: .number)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                    .background(AppTheme.cardTertiary)
                    .onChange(of: set.weight) { _, _ in
                        try? modelContext.save()
                    }
            }
            
            Spacer()
            
            // Completion toggle (editable)
            Button(action: {
                if set.completedAt != nil {
                    set.completedAt = nil
                } else {
                    set.completedAt = Date()
                }
                try? modelContext.save()
            }) {
                Image(systemName: set.completedAt != nil ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(set.completedAt != nil ? AppTheme.accentPrimary : AppTheme.textTertiary)
                    .font(.title3)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WorkoutHistory.self, WorkoutEntry.self, WorkoutSet.self, configurations: config)
    
    let sampleWorkout = WorkoutHistory(
        startedAt: Date().addingTimeInterval(-3600),
        completedAt: Date(),
        templateName: "Sample Workout",
        durationSeconds: 3600
    )
    
    return NavigationView {
        WorkoutHistoryEditView(workout: sampleWorkout)
    }
    .modelContainer(container)
}


