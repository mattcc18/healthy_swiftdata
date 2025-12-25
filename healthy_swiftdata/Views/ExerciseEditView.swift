//
//  ExerciseEditView.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 25/12/2025.
//

import SwiftUI
import SwiftData

struct ExerciseEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let exercise: ExerciseTemplate?
    
    @State private var name: String
    @State private var category: String?
    @State private var muscleGroupsText: String
    @State private var notes: String
    
    private let availableCategories = ["Strength", "Cardio", "Flexibility", "Other"]
    
    init(exercise: ExerciseTemplate? = nil) {
        self.exercise = exercise
        
        if let exercise = exercise {
            _name = State(initialValue: exercise.name)
            _category = State(initialValue: exercise.category)
            _muscleGroupsText = State(initialValue: exercise.muscleGroups.joined(separator: ", "))
            _notes = State(initialValue: exercise.notes ?? "")
        } else {
            _name = State(initialValue: "")
            _category = State(initialValue: nil)
            _muscleGroupsText = State(initialValue: "")
            _notes = State(initialValue: "")
        }
    }
    
    private var muscleGroups: [String] {
        muscleGroupsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
    
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && category != nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Exercise Details") {
                    TextField("Exercise Name", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    Picker("Category", selection: $category) {
                        Text("Select Category").tag(nil as String?)
                        ForEach(availableCategories, id: \.self) { category in
                            Text(category).tag(category as String?)
                        }
                    }
                    
                    TextField("Muscle Groups (comma-separated)", text: $muscleGroupsText, axis: .vertical)
                        .lineLimit(2...4)
                        .textInputAutocapitalization(.words)
                }
                
                Section("Notes") {
                    TextField("Notes (Optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(exercise == nil ? "New Exercise" : "Edit Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveExercise()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private func saveExercise() {
        if let exercise = exercise {
            // Update existing exercise
            exercise.name = name.trimmingCharacters(in: .whitespaces)
            exercise.category = category
            exercise.muscleGroups = muscleGroups
            exercise.notes = notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces)
            
            try? modelContext.save()
        } else {
            // Create new exercise
            let newExercise = ExerciseTemplate(
                name: name.trimmingCharacters(in: .whitespaces),
                category: category,
                muscleGroups: muscleGroups,
                icon: "figure.strengthtraining.traditional",
                iconColor: "#007AFF",
                notes: notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces)
            )
            
            modelContext.insert(newExercise)
            try? modelContext.save()
        }
        
        dismiss()
    }
}

#Preview {
    ExerciseEditView()
        .modelContainer(for: [ExerciseTemplate.self], inMemory: true)
}

