//
//  WorkoutTemplatesView.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 27/01/2025.
//

import SwiftUI
import SwiftData

struct WorkoutTemplatesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [
        SortDescriptor(\WorkoutTemplate.lastUsed, order: .reverse),
        SortDescriptor(\WorkoutTemplate.createdAt, order: .reverse)
    ]) private var workoutTemplates: [WorkoutTemplate]
    
    @Query private var activeWorkouts: [ActiveWorkout]
    
    @State private var showingCreateTemplate = false
    @State private var selectedTemplateForEdit: WorkoutTemplate?
    @State private var showingDeleteConfirmation = false
    @State private var templateToDelete: WorkoutTemplate?
    @State private var showingDiscardConfirmation = false
    @State private var templateToStart: WorkoutTemplate?
    
    private var activeWorkout: ActiveWorkout? {
        activeWorkouts.first
    }
    
    var body: some View {
        NavigationView {
            Group {
                if workoutTemplates.isEmpty {
                    emptyState
                } else {
                    templateList
                }
            }
            .navigationTitle("Workout Templates")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateTemplate = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateTemplate) {
                WorkoutTemplateEditView(template: nil)
            }
            .sheet(item: $selectedTemplateForEdit) { template in
                WorkoutTemplateEditView(template: template)
            }
            .alert("Discard Existing Workout?", isPresented: $showingDiscardConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Discard", role: .destructive) {
                    if let template = templateToStart {
                        discardAndStartWorkout(from: template)
                    }
                }
            } message: {
                Text("Starting a new workout will discard your current active workout. This cannot be undone.")
            }
            .alert("Delete Template", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let template = templateToDelete {
                        deleteTemplate(template)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this template? Active workouts started from this template will not be affected.")
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No Templates")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Create a workout template to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Button("Create Template") {
                showingCreateTemplate = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var templateList: some View {
        List {
            ForEach(workoutTemplates) { template in
                WorkoutTemplateRow(
                    template: template,
                    onTap: {
                        startWorkout(from: template)
                    },
                    onEdit: {
                        selectedTemplateForEdit = template
                    },
                    onDelete: {
                        templateToDelete = template
                        showingDeleteConfirmation = true
                    }
                )
            }
        }
    }
    
    private func deleteTemplate(_ template: WorkoutTemplate) {
        modelContext.delete(template)
        try? modelContext.save()
    }
    
    private func startWorkout(from template: WorkoutTemplate) {
        // Check if there's an existing active workout
        if activeWorkout != nil {
            // Show discard confirmation
            templateToStart = template
            showingDiscardConfirmation = true
        } else {
            // No existing workout, create new one directly
            createWorkoutFromTemplate(template)
        }
    }
    
    private func discardAndStartWorkout(from template: WorkoutTemplate) {
        // Delete existing workout first
        if let workout = activeWorkout {
            modelContext.delete(workout)
            try? modelContext.save()
        }
        // Then create new workout from template
        createWorkoutFromTemplate(template)
    }
    
    private func createWorkoutFromTemplate(_ template: WorkoutTemplate) {
        // Create new ActiveWorkout with template reference
        let newWorkout = ActiveWorkout(
            startedAt: Date(),
            templateName: template.name,
            notes: nil,
            workoutTemplate: template
        )
        
        // Update template's lastUsed
        template.lastUsed = Date()
        
        // Get template exercises sorted by order
        guard let templateExercises = template.exercises?.sorted(by: { $0.order < $1.order }) else {
            // No exercises in template, just insert workout
            modelContext.insert(newWorkout)
            try? modelContext.save()
            return
        }
        
        // Create WorkoutEntry and WorkoutSet objects for each template exercise
        for templateExercise in templateExercises {
            // Create WorkoutEntry
            let entry = WorkoutEntry(
                exerciseTemplate: templateExercise.exerciseTemplate,
                exerciseName: templateExercise.exerciseName,
                order: templateExercise.order
            )
            entry.activeWorkout = newWorkout
            
            // Create WorkoutSet objects for this exercise
            for setNumber in 1...templateExercise.numberOfSets {
                let workoutSet = WorkoutSet(
                    setNumber: setNumber,
                    reps: templateExercise.targetReps,
                    weight: nil,
                    restTime: templateExercise.restTimeSeconds,
                    completedAt: nil
                )
                workoutSet.workoutEntry = entry
                
                if entry.sets == nil {
                    entry.sets = []
                }
                entry.sets?.append(workoutSet)
                
                modelContext.insert(workoutSet)
            }
            
            if newWorkout.entries == nil {
                newWorkout.entries = []
            }
            newWorkout.entries?.append(entry)
            
            modelContext.insert(entry)
        }
        
        // Insert workout and save
        modelContext.insert(newWorkout)
        try? modelContext.save()
        
        // Note: Tab switching will be handled in Phase 7 when integrating into MainTabView
    }
}

struct WorkoutTemplateRow: View {
    let template: WorkoutTemplate
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var exerciseCount: Int {
        template.exercises?.count ?? 0
    }
    
    var estimatedDuration: Int {
        // Rough estimate: 3 minutes per exercise (sets + rest time)
        exerciseCount * 3
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(template.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 16) {
                        Label("\(exerciseCount) exercises", systemImage: "figure.strengthtraining.traditional")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Label("~\(estimatedDuration) min", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let lastUsed = template.lastUsed {
                        Text("Last used: \(lastUsed, style: .date)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Edit button
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
            
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    WorkoutTemplatesView()
        .modelContainer(for: [WorkoutTemplate.self, TemplateExercise.self, ExerciseTemplate.self], inMemory: true)
}

