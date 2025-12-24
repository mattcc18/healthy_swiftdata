//
//  ActiveWorkout.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 27/01/2025.
//

import Foundation
import SwiftData

@Model
final class ActiveWorkout {
    var id: UUID
    var startedAt: Date
    var templateName: String? // Optional reference to template used
    var notes: String?
    
    // Exercise entries for this workout
    @Relationship(deleteRule: .cascade) var entries: [WorkoutEntry]?
    
    init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        templateName: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.templateName = templateName
        self.notes = notes
    }
}

