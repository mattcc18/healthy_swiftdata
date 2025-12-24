//
//  ExercisesView.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 27/01/2025.
//

import SwiftUI
import SwiftData

struct ExercisesView: View {
    @Query private var exerciseTemplates: [ExerciseTemplate]
    @State private var searchText = ""
    @State private var selectedCategory: String?
    
    var filteredExercises: [ExerciseTemplate] {
        var filtered = exerciseTemplates
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { template in
                template.name.localizedCaseInsensitiveContains(searchText) ||
                template.muscleGroups.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Filter by category
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        return filtered
    }
    
    var availableCategories: [String] {
        let categories = Set(exerciseTemplates.compactMap { $0.category }.filter { !$0.isEmpty })
        return Array(categories).sorted()
    }
    
    var groupedExercises: [String: [ExerciseTemplate]] {
        Dictionary(grouping: filteredExercises) { exercise in
            exercise.category ?? "Other"
        }
    }
    
    var sortedGroupKeys: [String] {
        groupedExercises.keys.sorted()
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
                
                // Exercises grouped by category
                if filteredExercises.isEmpty {
                    Section {
                        Text("No exercises found")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                } else if selectedCategory != nil {
                    // Show flat list when category is selected
                    ForEach(filteredExercises.sorted(by: { $0.name < $1.name }), id: \.id) { template in
                        ExerciseRow(template: template)
                    }
                } else {
                    // Show grouped by category
                    ForEach(sortedGroupKeys, id: \.self) { category in
                        Section(header: Text(category)) {
                            if let exercises = groupedExercises[category] {
                                ForEach(exercises.sorted(by: { $0.name < $1.name }), id: \.id) { template in
                                    ExerciseRow(template: template)
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Exercises")
        }
    }
}

struct CategoryFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .cornerRadius(20)
        }
    }
}

struct ExerciseRow: View {
    let template: ExerciseTemplate
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: template.icon)
                .font(.title2)
                .foregroundColor(colorFromHex(template.iconColor))
                .frame(width: 40, height: 40)
                .background(colorFromHex(template.iconColor).opacity(0.1))
                .cornerRadius(8)
            
            // Exercise info
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.headline)
                
                if !template.muscleGroups.isEmpty {
                    Text(template.muscleGroups.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let category = template.category {
                    Text(category)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
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

