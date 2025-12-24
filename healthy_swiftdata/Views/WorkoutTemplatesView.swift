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
    
    @State private var showingCreateTemplate = false
    @State private var selectedTemplate: WorkoutTemplate?
    @State private var showingDeleteConfirmation = false
    @State private var templateToDelete: WorkoutTemplate?
    
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
            .sheet(item: $selectedTemplate) { template in
                WorkoutTemplateEditView(template: template)
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
                        selectedTemplate = template
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
}

struct WorkoutTemplateRow: View {
    let template: WorkoutTemplate
    let onTap: () -> Void
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
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
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

