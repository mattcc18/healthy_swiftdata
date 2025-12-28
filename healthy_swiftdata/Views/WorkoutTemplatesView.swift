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
    
    @Binding var selectedTab: Int
    
    @State private var showingCreateTemplate = false
    @State private var selectedTemplateForEdit: WorkoutTemplate?
    @State private var showingDeleteConfirmation = false
    @State private var templateToDelete: WorkoutTemplate?
    @State private var showingDiscardConfirmation = false
    @State private var templateToStart: WorkoutTemplate?
    
    init(selectedTab: Binding<Int> = .constant(0)) {
        _selectedTab = selectedTab
    }
    
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
                .foregroundColor(AppTheme.textSecondary)
            Text("No Templates")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.textPrimary)
            Text("Create a workout template to get started")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
            Button("Create Template") {
                showingCreateTemplate = true
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accentPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background)
    }
    
    private var templateList: some View {
        let groupedTemplates = Dictionary(grouping: workoutTemplates) { template -> WorkoutType? in
            template.workoutType.flatMap { WorkoutType(rawValue: $0) }
        }
        
        // Sort workout types: strength, stretching, cardio, then nil
        let sortedTypes: [WorkoutType?] = [
            .strength,
            .stretching,
            .cardio,
            nil
        ]
        
        return List {
            ForEach(sortedTypes, id: \.self) { workoutType in
                if let templates = groupedTemplates[workoutType], !templates.isEmpty {
                    Section {
                        ForEach(templates) { template in
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
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                        }
                    } header: {
                        if let workoutType = workoutType {
                            HStack {
                                Circle()
                                    .fill(workoutType.color)
                                    .frame(width: 8, height: 8)
                                Text(workoutType.displayName)
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        } else {
                            Text("Uncategorized")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
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
        guard let templateExercises = template.exercises?.sorted(by: { $0.order < $1.order }), !templateExercises.isEmpty else {
            // No exercises in template, just insert workout
            modelContext.insert(newWorkout)
            try? modelContext.save()
            selectedTab = 1
            return
        }
        
        // Create WorkoutEntry and WorkoutSet objects for each template exercise
        for templateExercise in templateExercises {
            // Ensure numberOfSets is at least 1
            let setsToCreate = max(1, templateExercise.numberOfSets)
            // Create WorkoutEntry
            let entry = WorkoutEntry(
                exerciseTemplate: templateExercise.exerciseTemplate,
                exerciseName: templateExercise.exerciseName,
                order: templateExercise.order
            )
            entry.activeWorkout = newWorkout
            
            // Create WorkoutSet objects for this exercise
            for setNumber in 1...setsToCreate {
                // Ensure rest time is not negative
                let restTime = max(0, templateExercise.restTimeSeconds)
                let workoutSet = WorkoutSet(
                    setNumber: setNumber,
                    reps: templateExercise.targetReps,
                    weight: nil,
                    restTime: restTime,
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
        
        // Switch to Active Workout tab
        selectedTab = 1
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
    
    var workoutTypeColor: Color {
        if let typeString = template.workoutType,
           let type = WorkoutType(rawValue: typeString) {
            return type.color
        }
        return AppTheme.accentPrimary
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(template.name)
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
                // Play button on the right - color matches workout type
                ZStack {
                    Circle()
                        .fill(workoutTypeColor)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "play.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .offset(x: 1)
                }
            }
            
            // Workout type tag under title
            if let typeString = template.workoutType,
               let type = WorkoutType(rawValue: typeString) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(type.color)
                        .frame(width: 6, height: 6)
                    Text(type.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(type.color)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(type.color.opacity(0.15))
                .cornerRadius(6)
            }
            
            HStack(spacing: 16) {
                Label("\(exerciseCount) exercises", systemImage: "figure.strengthtraining.traditional")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                
                Label("~\(estimatedDuration) min", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardPrimary)
        .cornerRadius(AppTheme.cornerRadiusMedium)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .contextMenu {
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: WorkoutTemplate.self, TemplateExercise.self, ExerciseTemplate.self, configurations: config)
        
        // Create sample workout templates
        let template1 = WorkoutTemplate(
            name: "Push Day",
            createdAt: Date().addingTimeInterval(-86400 * 7), // 7 days ago
            lastUsed: Date().addingTimeInterval(-86400 * 2) // 2 days ago
        )
        
        let template2 = WorkoutTemplate(
            name: "Pull Day",
            createdAt: Date().addingTimeInterval(-86400 * 5), // 5 days ago
            lastUsed: Date().addingTimeInterval(-86400) // 1 day ago
        )
        
        // Add exercises to template1
        let exercise1_1 = TemplateExercise(
            exerciseName: "Bench Press",
            order: 1,
            targetReps: 8,
            numberOfSets: 4,
            restTimeSeconds: 90
        )
        exercise1_1.workoutTemplate = template1
        
        let exercise1_2 = TemplateExercise(
            exerciseName: "Overhead Press",
            order: 2,
            targetReps: 10,
            numberOfSets: 3,
            restTimeSeconds: 60
        )
        exercise1_2.workoutTemplate = template1
        
        let exercise1_3 = TemplateExercise(
            exerciseName: "Tricep Dips",
            order: 3,
            targetReps: 12,
            numberOfSets: 3,
            restTimeSeconds: 45
        )
        exercise1_3.workoutTemplate = template1
        
        template1.exercises = [exercise1_1, exercise1_2, exercise1_3]
        
        // Add exercises to template2
        let exercise2_1 = TemplateExercise(
            exerciseName: "Deadlift",
            order: 1,
            targetReps: 5,
            numberOfSets: 5,
            restTimeSeconds: 180
        )
        exercise2_1.workoutTemplate = template2
        
        let exercise2_2 = TemplateExercise(
            exerciseName: "Barbell Row",
            order: 2,
            targetReps: 8,
            numberOfSets: 4,
            restTimeSeconds: 90
        )
        exercise2_2.workoutTemplate = template2
        
        let exercise2_3 = TemplateExercise(
            exerciseName: "Pull-ups",
            order: 3,
            targetReps: 10,
            numberOfSets: 3,
            restTimeSeconds: 60
        )
        exercise2_3.workoutTemplate = template2
        
        let exercise2_4 = TemplateExercise(
            exerciseName: "Bicep Curls",
            order: 4,
            targetReps: 12,
            numberOfSets: 3,
            restTimeSeconds: 45
        )
        exercise2_4.workoutTemplate = template2
        
        template2.exercises = [exercise2_1, exercise2_2, exercise2_3, exercise2_4]
        
        // Insert into container
        container.mainContext.insert(template1)
        container.mainContext.insert(template2)
        container.mainContext.insert(exercise1_1)
        container.mainContext.insert(exercise1_2)
        container.mainContext.insert(exercise1_3)
        container.mainContext.insert(exercise2_1)
        container.mainContext.insert(exercise2_2)
        container.mainContext.insert(exercise2_3)
        container.mainContext.insert(exercise2_4)
        
        return WorkoutTemplatesView(selectedTab: .constant(0))
            .modelContainer(container)
    } catch {
        return Text("Preview Error: \(error.localizedDescription)")
    }
}

