//
//  WorkoutTemplate.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 27/01/2025.
//

import Foundation
import SwiftData
import SwiftUI

enum WorkoutType: String, Codable, CaseIterable {
    case strength = "strength"
    case stretching = "stretching"
    case cardio = "cardio"
    
    var displayName: String {
        switch self {
        case .strength: return "Strength"
        case .stretching: return "Stretching"
        case .cardio: return "Cardio"
        }
    }
    
    var color: Color {
        switch self {
        case .strength: return Color.green
        case .stretching: return Color.pink
        case .cardio: return Color.blue
        }
    }
}

@Model
final class WorkoutTemplate {
    var id: UUID
    var name: String
    var notes: String?
    var createdAt: Date
    var lastUsed: Date?
    var workoutType: String? // "strength", "stretching", or "cardio"
    
    // Relationship to TemplateExercise
    @Relationship(deleteRule: .cascade) var exercises: [TemplateExercise]?
    
    init(
        id: UUID = UUID(),
        name: String,
        notes: String? = nil,
        createdAt: Date = Date(),
        lastUsed: Date? = nil,
        workoutType: String? = nil
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.createdAt = createdAt
        self.lastUsed = lastUsed
        self.workoutType = workoutType
    }
}






