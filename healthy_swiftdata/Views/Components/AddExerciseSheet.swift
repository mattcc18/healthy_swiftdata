//
//  AddExerciseSheet.swift
//  healthy_swiftdata
//
//  Extracted from ActiveWorkoutView.swift for better code organization
//

import SwiftUI
import SwiftData

struct AddExerciseSheet: View {
    let exerciseTemplates: [ExerciseTemplate]
    let onAddExercises: ([String]) -> Void
    @State private var searchText = ""
    @State private var selectedBodyPart: String? = nil
    @State private var selectedExercises: Set<UUID> = []
    @Environment(\.dismiss) private var dismiss
    
    var availableBodyParts: [String] {
        let bodyParts = Set(exerciseTemplates.flatMap { $0.muscleGroups }.filter { !$0.isEmpty })
        return Array(bodyParts).sorted()
    }
    
    var filteredTemplates: [ExerciseTemplate] {
        var filtered = exerciseTemplates
        
        // Filter by body part
        if let bodyPart = selectedBodyPart {
            filtered = filtered.filter { $0.muscleGroups.contains(bodyPart) }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { template in
                template.name.localizedCaseInsensitiveContains(searchText) ||
                template.muscleGroups.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            List {
                // Body part filter buttons
                if !availableBodyParts.isEmpty {
                    Section {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                // "All" button
                                CategoryFilterButton(
                                    title: "All",
                                    isSelected: selectedBodyPart == nil,
                                    action: {
                                        selectedBodyPart = nil
                                    }
                                )
                                
                                // Body part buttons
                                ForEach(availableBodyParts, id: \.self) { bodyPart in
                                    CategoryFilterButton(
                                        title: bodyPart,
                                        isSelected: selectedBodyPart == bodyPart,
                                        action: {
                                            selectedBodyPart = selectedBodyPart == bodyPart ? nil : bodyPart
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        .listRowInsets(EdgeInsets())
                    }
                }
                
                if exerciseTemplates.isEmpty {
                    Section {
                        Text("No exercises available")
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .listRowBackground(AppTheme.cardPrimary)
                } else if filteredTemplates.isEmpty {
                    Section {
                        Text("No exercises found")
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .listRowBackground(AppTheme.cardPrimary)
                } else {
                    Section(header: Text("Exercises")) {
                        ForEach(filteredTemplates, id: \.id) { template in
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
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Add Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add Selected (\(selectedExercises.count))") {
                        let selectedNames = filteredTemplates
                            .filter { selectedExercises.contains($0.id) }
                            .map { $0.name }
                        onAddExercises(selectedNames)
                        dismiss()
                    }
                    .disabled(selectedExercises.isEmpty)
                }
            }
        }
    }
}


