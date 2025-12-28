//
//  WorkoutTemplateEditView.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 27/01/2025.
//

import SwiftUI
import SwiftData

struct WorkoutTemplateEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var exerciseTemplates: [ExerciseTemplate]
    
    let template: WorkoutTemplate?
    
    @State private var templateName: String
    @State private var templateNotes: String
    @State private var templateExercises: [TemplateExerciseEditItem]
    @State private var selectedWorkoutType: WorkoutType?
    @State private var showingAddExercise = false
    
    init(template: WorkoutTemplate?) {
        self.template = template
        
        if let template = template {
            _templateName = State(initialValue: template.name)
            _templateNotes = State(initialValue: template.notes ?? "")
            _selectedWorkoutType = State(initialValue: template.workoutType.flatMap { WorkoutType(rawValue: $0) })
            
            // Load existing template exercises
            let exercises = template.exercises?.sorted(by: { $0.order < $1.order }) ?? []
            _templateExercises = State(initialValue: exercises.map { exercise in
                TemplateExerciseEditItem(
                    id: exercise.id,
                    exerciseTemplate: exercise.exerciseTemplate,
                    exerciseName: exercise.exerciseName,
                    order: exercise.order,
                    targetReps: exercise.targetReps,
                    numberOfSets: exercise.numberOfSets,
                    restTimeSeconds: exercise.restTimeSeconds,
                    notes: exercise.notes
                )
            })
        } else {
            _templateName = State(initialValue: "")
            _templateNotes = State(initialValue: "")
            _templateExercises = State(initialValue: [])
            _selectedWorkoutType = State(initialValue: nil)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Template Details") {
                    TextField("Template Name", text: $templateName)
                        .textInputAutocapitalization(.words)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Picker("Workout Type", selection: $selectedWorkoutType) {
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
                    
                    TextField("Notes (Optional)", text: $templateNotes, axis: .vertical)
                        .lineLimit(3...6)
                        .foregroundColor(AppTheme.textPrimary)
                }
                .listRowBackground(AppTheme.cardPrimary)
                
                Section("Exercises") {
                    if templateExercises.isEmpty {
                        Text("No exercises added yet")
                            .foregroundColor(AppTheme.textSecondary)
                            .font(.caption)
                    } else {
                        ForEach(templateExercises.indices, id: \.self) { index in
                            TemplateExerciseEditRow(
                                item: $templateExercises[index],
                                onDelete: {
                                    templateExercises.remove(at: index)
                                    updateOrders()
                                }
                            )
                        }
                        .onMove { source, destination in
                            templateExercises.move(fromOffsets: source, toOffset: destination)
                            updateOrders()
                        }
                    }
                    
                    Button(action: {
                        showingAddExercise = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Exercise")
                        }
                        .foregroundColor(AppTheme.accentPrimary)
                    }
                }
                .listRowBackground(AppTheme.cardPrimary)
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .navigationTitle(template == nil ? "New Template" : "Edit Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTemplate()
                    }
                    .disabled(templateName.isEmpty || templateExercises.isEmpty)
                }
            }
            .sheet(isPresented: $showingAddExercise) {
                AddExerciseToTemplateSheet(
                    exerciseTemplates: exerciseTemplates,
                    onSelectExercises: { exercises in
                        addExercisesToTemplate(exerciseTemplates: exercises)
                    }
                )
            }
        }
    }
    
    private func updateOrders() {
        for (index, _) in templateExercises.enumerated() {
            templateExercises[index].order = index
        }
    }
    
    private func addExerciseToTemplate(exerciseTemplate: ExerciseTemplate) {
        let nextOrder = templateExercises.isEmpty ? 0 : (templateExercises.map { $0.order }.max() ?? -1) + 1
        
        let newItem = TemplateExerciseEditItem(
            id: UUID(),
            exerciseTemplate: exerciseTemplate,
            exerciseName: exerciseTemplate.name,
            order: nextOrder,
            targetReps: nil,
            numberOfSets: 3,
            restTimeSeconds: 90,
            notes: nil
        )
        
        templateExercises.append(newItem)
        showingAddExercise = false
    }
    
    private func addExercisesToTemplate(exerciseTemplates: [ExerciseTemplate]) {
        let currentMaxOrder = templateExercises.isEmpty ? -1 : (templateExercises.map { $0.order }.max() ?? -1)
        
        for (index, exerciseTemplate) in exerciseTemplates.enumerated() {
            let newItem = TemplateExerciseEditItem(
                id: UUID(),
                exerciseTemplate: exerciseTemplate,
                exerciseName: exerciseTemplate.name,
                order: currentMaxOrder + 1 + index,
                targetReps: nil,
                numberOfSets: 3,
                restTimeSeconds: 90,
                notes: nil
            )
            
            templateExercises.append(newItem)
        }
        
        showingAddExercise = false
    }
    
    private func saveTemplate() {
        if let existingTemplate = template {
            // Update existing template
            existingTemplate.name = templateName
            existingTemplate.notes = templateNotes.isEmpty ? nil : templateNotes
            existingTemplate.workoutType = selectedWorkoutType?.rawValue
            
            // Delete old exercises
            if let oldExercises = existingTemplate.exercises {
                for exercise in oldExercises {
                    modelContext.delete(exercise)
                }
            }
            
            // Create new exercises
            for item in templateExercises {
                let exercise = TemplateExercise(
                    exerciseTemplate: item.exerciseTemplate,
                    exerciseName: item.exerciseName,
                    order: item.order,
                    targetReps: item.targetReps,
                    numberOfSets: item.numberOfSets,
                    restTimeSeconds: item.restTimeSeconds,
                    notes: item.notes
                )
                exercise.workoutTemplate = existingTemplate
                modelContext.insert(exercise)
            }
        } else {
            // Create new template
            let newTemplate = WorkoutTemplate(
                name: templateName,
                notes: templateNotes.isEmpty ? nil : templateNotes,
                workoutType: selectedWorkoutType?.rawValue
            )
            modelContext.insert(newTemplate)
            
            // Create exercises
            for item in templateExercises {
                let exercise = TemplateExercise(
                    exerciseTemplate: item.exerciseTemplate,
                    exerciseName: item.exerciseName,
                    order: item.order,
                    targetReps: item.targetReps,
                    numberOfSets: item.numberOfSets,
                    restTimeSeconds: item.restTimeSeconds,
                    notes: item.notes
                )
                exercise.workoutTemplate = newTemplate
                modelContext.insert(exercise)
            }
        }
        
        try? modelContext.save()
        dismiss()
    }
}

struct TemplateExerciseEditItem {
    var id: UUID
    var exerciseTemplate: ExerciseTemplate?
    var exerciseName: String
    var order: Int
    var targetReps: Int?
    var numberOfSets: Int
    var restTimeSeconds: Int
    var notes: String?
}

struct TemplateExerciseEditRow: View {
    @Binding var item: TemplateExerciseEditItem
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(item.exerciseName)
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(AppTheme.gradientOrangeStart)
                }
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sets")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    Stepper(value: $item.numberOfSets, in: 1...10) {
                        Text("\(item.numberOfSets)")
                            .font(.body)
                            .frame(width: 30)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Target Reps")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    TextField("Reps", value: $item.targetReps, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .background(AppTheme.cardTertiary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rest (sec)")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        TextField("Rest", value: $item.restTimeSeconds, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .background(AppTheme.cardTertiary)
                        .onChange(of: item.restTimeSeconds) { oldValue, newValue in
                            // Ensure rest time is not negative
                            if newValue < 0 {
                                item.restTimeSeconds = 0
                            }
                        }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddExerciseToTemplateSheet: View {
    let exerciseTemplates: [ExerciseTemplate]
    let onSelectExercises: ([ExerciseTemplate]) -> Void
    @State private var searchText = ""
    @State private var selectedCategory: String?
    @State private var selectedExercises: Set<UUID> = []
    @Environment(\.dismiss) private var dismiss
    
    var availableCategories: [String] {
        let categories = Set(exerciseTemplates.compactMap { $0.category }.filter { !$0.isEmpty })
        return Array(categories).sorted()
    }
    
    var filteredTemplates: [ExerciseTemplate] {
        var filtered = exerciseTemplates
        
        // Filter by category
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { template in
                template.name.localizedCaseInsensitiveContains(searchText) ||
                template.muscleGroups.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        return filtered.sorted(by: { $0.name < $1.name })
    }
    
    var body: some View {
        NavigationView {
            List {
                // Category filter buttons
                if !availableCategories.isEmpty {
                    Section {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                // "All" button
                                CategoryFilterButton(
                                    title: "All",
                                    isSelected: selectedCategory == nil,
                                    action: {
                                        selectedCategory = nil
                                    }
                                )
                                
                                // Category buttons
                                ForEach(availableCategories, id: \.self) { category in
                                    CategoryFilterButton(
                                        title: category,
                                        isSelected: selectedCategory == category,
                                        action: {
                                            selectedCategory = selectedCategory == category ? nil : category
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        .listRowInsets(EdgeInsets())
                    }
                }
                
                ForEach(filteredTemplates) { template in
                    Button(action: {
                        if selectedExercises.contains(template.id) {
                            selectedExercises.remove(template.id)
                        } else {
                            selectedExercises.insert(template.id)
                        }
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.name)
                                    .font(.headline)
                                    .foregroundColor(AppTheme.textPrimary)
                                
                                if !template.muscleGroups.isEmpty {
                                    Text(template.muscleGroups.joined(separator: ", "))
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                            }
                            
                            Spacer()
                            
                            if selectedExercises.contains(template.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppTheme.accentPrimary)
                                    .font(.title3)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(AppTheme.textTertiary)
                                    .font(.title3)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Add Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Selected (\(selectedExercises.count))") {
                        let selected = exerciseTemplates.filter { selectedExercises.contains($0.id) }
                        onSelectExercises(selected)
                        dismiss()
                    }
                    .disabled(selectedExercises.isEmpty)
                }
            }
        }
    }
}

#Preview {
    WorkoutTemplateEditView(template: nil)
        .modelContainer(for: [WorkoutTemplate.self, TemplateExercise.self, ExerciseTemplate.self], inMemory: true)
}

