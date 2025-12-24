//
//  ExerciseTemplate.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 27/01/2025.
//

import Foundation
import SwiftData

@Model
final class ExerciseTemplate {
    var id: UUID
    var name: String
    var category: String?
    var muscleGroups: [String]
    var icon: String
    var iconColor: String // Store as hex string
    var notes: String?
    var createdAt: Date
    var lastUsed: Date?
    
    init(
        id: UUID = UUID(),
        name: String,
        category: String? = nil,
        muscleGroups: [String] = [],
        icon: String = "figure.strengthtraining.traditional",
        iconColor: String = "#007AFF",
        notes: String? = nil,
        createdAt: Date = Date(),
        lastUsed: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.muscleGroups = muscleGroups
        self.icon = icon
        self.iconColor = iconColor
        self.notes = notes
        self.createdAt = createdAt
        self.lastUsed = lastUsed
    }
}


