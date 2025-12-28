//
//  ExercisesView.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 27/01/2025.
//

import SwiftUI
import SwiftData

struct ExercisesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var exerciseTemplates: [ExerciseTemplate]
    @State private var searchText = ""
    @State private var selectedBodyPart: String? = "Favorites" // Default to favorites = "Favorites" // Default to favorites
    @State private var showingEditSheet = false
    @State private var exerciseToEdit: ExerciseTemplate?
    @State private var exerciseToDelete: ExerciseTemplate?
    @State private var showingDeleteConfirmation = false
    
    private var filteredExercises: [ExerciseTemplate] {
        var filtered = exerciseTemplates
        
        // Filter by selected filter (Favorites or body part)
        if let filter = selectedBodyPart {
            if filter == "Favorites" {
                // Show only favorites
                filtered = filtered.filter { exercise in
                    exercise.isFavorite == true
                }
            } else {
                // Show all exercises for the selected body part (ignore favorites)
                filtered = filtered.filter { exercise in
                    exercise.muscleGroups.contains(filter)
                }
            }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            filtered = filtered.filter { template in
                template.name.lowercased().contains(searchLower) ||
                template.muscleGroups.contains { group in
                    group.lowercased().contains(searchLower)
                }
            }
        }
        
        return filtered
    }
    
    private var availableBodyParts: [String] {
        var bodyParts = Set<String>()
        for exercise in exerciseTemplates {
            for group in exercise.muscleGroups where !group.isEmpty {
                bodyParts.insert(group)
            }
        }
        return Array(bodyParts).sorted()
    }
    
    private var groupedExercises: [String: [ExerciseTemplate]] {
        let filtered = filteredExercises
        var grouped: [String: [ExerciseTemplate]] = [:]
        
        for exercise in filtered {
            let key = exercise.muscleGroups.first ?? "Other"
            if grouped[key] == nil {
                grouped[key] = []
            }
            grouped[key]?.append(exercise)
        }
        
        return grouped
    }
    
    private var sortedGroupKeys: [String] {
        let grouped = groupedExercises
        return grouped.keys.sorted()
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Filter buttons (Favorites + Body parts)
                if !availableBodyParts.isEmpty {
                    Section {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                // Favorites button (default)
                                CategoryFilterButton(
                                    title: "Favorites",
                                    icon: "star.fill",
                                    isSelected: selectedBodyPart == "Favorites",
                                    action: {
                                        selectedBodyPart = selectedBodyPart == "Favorites" ? nil : "Favorites"
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
                
                // Exercises grouped by category
                exercisesListContent
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .listRowBackground(AppTheme.cardPrimary)
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Exercises")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        exerciseToEdit = nil
                        showingEditSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .foregroundColor(AppTheme.accentPrimary)
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                ExerciseEditView(exercise: exerciseToEdit)
            }
            .alert("Delete Exercise", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let exercise = exerciseToDelete {
                        deleteExercise(exercise)
                    }
                }
            } message: {
                if let exercise = exerciseToDelete {
                    Text("Are you sure you want to delete \"\(exercise.name)\"? This will not affect workout templates that use this exercise.")
                }
            }
        }
    }
    
    private func deleteExercise(_ exercise: ExerciseTemplate) {
        modelContext.delete(exercise)
        try? modelContext.save()
        exerciseToDelete = nil
    }
    
    private func toggleFavorite(_ exercise: ExerciseTemplate) {
        exercise.isFavorite = (exercise.isFavorite == true) ? false : true
        try? modelContext.save()
    }
    
    @ViewBuilder
    private var exercisesListContent: some View {
        let filtered = filteredExercises
        let grouped = groupedExercises
        let sortedKeys = sortedGroupKeys
        
        if filtered.isEmpty {
            Section {
                Text("No exercises found")
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
            .listRowBackground(AppTheme.cardPrimary)
        } else if selectedBodyPart != nil && selectedBodyPart != "Favorites" {
            // Show flat list when body part is selected (not favorites)
            ForEach(filtered.sorted(by: { $0.name < $1.name }), id: \.id) { template in
                exerciseRowWithActions(template: template)
            }
        } else {
            // Show grouped by category
            ForEach(sortedKeys, id: \.self) { category in
                Section(header: Text(category)) {
                    if let exercises = grouped[category] {
                        ForEach(exercises.sorted(by: { $0.name < $1.name }), id: \.id) { template in
                            exerciseRowWithActions(template: template)
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func exerciseRowWithActions(template: ExerciseTemplate) -> some View {
        NavigationLink(destination: ExerciseDetailView(exercise: template)) {
            ExerciseRow(template: template)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                toggleFavorite(template)
            } label: {
                Label((template.isFavorite == true) ? "Unfavorite" : "Favorite", 
                      systemImage: (template.isFavorite == true) ? "star.fill" : "star")
            }
            .tint(AppTheme.accentPrimary)
            
            Button {
                exerciseToEdit = template
                showingEditSheet = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(AppTheme.accentPrimary)
            
            Button(role: .destructive) {
                exerciseToDelete = template
                showingDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - CategoryFilterButton extracted to Views/Components/CategoryFilterButton.swift

struct ExerciseRow: View {
    let template: ExerciseTemplate
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: template.icon)
                .font(.title2)
                .foregroundColor(colorFromHex(template.iconColor))
                .frame(width: 48, height: 48)
                .background(colorFromHex(template.iconColor).opacity(0.15))
                .cornerRadius(AppTheme.cornerRadiusSmall)
            
            // Exercise info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(template.name)
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    if template.isFavorite == true {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(AppTheme.accentPrimary)
                    }
                }
                
                if !template.muscleGroups.isEmpty {
                    Text(template.muscleGroups.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                if let category = template.category {
                    Text(category)
                        .font(.caption2)
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.cardTertiary)
                        .cornerRadius(AppTheme.cornerRadiusSmall)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func colorFromHex(_ hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return Color.blue
        }
        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ExercisesView()
        .modelContainer(for: [ExerciseTemplate.self], inMemory: true)
}

