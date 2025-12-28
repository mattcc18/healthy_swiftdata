//
//  WorkoutEntry.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 27/01/2025.
//

import Foundation
import SwiftData

@Model
final class WorkoutEntry {
    var id: UUID
    var exerciseTemplate: ExerciseTemplate?
    var exerciseName: String // Snapshot of exercise name at workout time
    var order: Int
    var notes: String?
    var createdAt: Date
    var isWarmup: Bool?
    
    // Relationship to ActiveWorkout
    var activeWorkout: ActiveWorkout?
    
    // Relationship to WorkoutHistory (for completed workouts)
    var workoutHistory: WorkoutHistory?
    
    // Sets for this exercise entry
    @Relationship(deleteRule: .cascade) var sets: [WorkoutSet]?
    
    init(
        id: UUID = UUID(),
        exerciseTemplate: ExerciseTemplate? = nil,
        exerciseName: String,
        order: Int,
        notes: String? = nil,
        createdAt: Date = Date(),
        isWarmup: Bool? = false
    ) {
        self.id = id
        self.exerciseTemplate = exerciseTemplate
        self.exerciseName = exerciseName
        self.order = order
        self.notes = notes
        self.createdAt = createdAt
        self.isWarmup = isWarmup
    }
}


