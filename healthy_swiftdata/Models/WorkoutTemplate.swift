//
//  WorkoutTemplate.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 27/01/2025.
//

import Foundation
import SwiftData

@Model
final class WorkoutTemplate {
    var id: UUID
    var name: String
    var notes: String?
    var createdAt: Date
    var lastUsed: Date?
    
    // Relationship to TemplateExercise
    @Relationship(deleteRule: .cascade) var exercises: [TemplateExercise]?
    
    init(
        id: UUID = UUID(),
        name: String,
        notes: String? = nil,
        createdAt: Date = Date(),
        lastUsed: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.createdAt = createdAt
        self.lastUsed = lastUsed
    }
}

