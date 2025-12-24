//
//  WorkoutHistoryDetailView.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 27/01/2025.
//

import SwiftUI
import SwiftData

struct WorkoutHistoryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let workout: WorkoutHistory
    
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        List {
            // Workout header
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Completed: \(workout.completedAt, style: .date)")
                        .font(.headline)
                    
                    if let duration = workout.durationSeconds {
                        Text("Duration: \(formatDuration(duration))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let templateName = workout.templateName {
                        Text("Template: \(templateName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let volume = workout.totalVolume {
                        Text("Total Volume: \(String(format: "%.1f kg", volume))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let notes = workout.notes, !notes.isEmpty {
                        Text("Notes: \(notes)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
                .padding(.vertical, 4)
            }
            
            // Exercises and sets
            if let entries = workout.entries, !entries.isEmpty {
                ForEach(entries.sorted(by: { $0.order < $1.order }), id: \.id) { entry in
                    Section(header: Text(entry.exerciseName)) {
                        if let sets = entry.sets, !sets.isEmpty {
                            ForEach(sets.sorted(by: { $0.setNumber < $1.setNumber }), id: \.id) { set in
                                SetDetailRow(set: set)
                            }
                        } else {
                            Text("No sets")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        
                        if let notes = entry.notes, !notes.isEmpty {
                            Text("Notes: \(notes)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                    }
                }
            } else {
                Section {
                    Text("No exercises")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Workout Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .alert("Delete Workout", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteWorkout()
            }
        } message: {
            Text("Are you sure you want to delete this workout? This action cannot be undone.")
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
    
    private func deleteWorkout() {
        modelContext.delete(workout)
        try? modelContext.save()
        dismiss()
    }
}

struct SetDetailRow: View {
    let set: WorkoutSet
    
    var body: some View {
        HStack {
            // Set number
            Text("Set \(set.setNumber)")
                .font(.headline)
                .frame(width: 60, alignment: .leading)
            
            Spacer()
            
            // Reps
            if let reps = set.reps {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(reps)")
                        .font(.body)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("-")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Weight
            if let weight = set.weight {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weight")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f kg", weight))
                        .font(.body)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weight")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("-")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Completion status
            Image(systemName: set.completedAt != nil ? "checkmark.circle.fill" : "circle")
                .foregroundColor(set.completedAt != nil ? .green : .gray)
                .font(.title3)
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
        WorkoutHistoryDetailView(workout: sampleWorkout)
    }
    .modelContainer(container)
}

