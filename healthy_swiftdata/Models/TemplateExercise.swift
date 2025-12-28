//
//  TemplateExercise.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 27/01/2025.
//

import Foundation
import SwiftData

@Model
final class TemplateExercise {
    var id: UUID
    var exerciseTemplate: ExerciseTemplate?
    var exerciseName: String // Snapshot of exercise name at template creation time
    var order: Int
    var targetReps: Int?
    var numberOfSets: Int
    var restTimeSeconds: Int
    var notes: String?
    var createdAt: Date
    
    // Relationship to WorkoutTemplate
    var workoutTemplate: WorkoutTemplate?
    
    init(
        id: UUID = UUID(),
        exerciseTemplate: ExerciseTemplate? = nil,
        exerciseName: String,
        order: Int,
        targetReps: Int? = nil,
        numberOfSets: Int = 3,
        restTimeSeconds: Int = 90,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.exerciseTemplate = exerciseTemplate
        self.exerciseName = exerciseName
        self.order = order
        self.targetReps = targetReps
        self.numberOfSets = numberOfSets
        self.restTimeSeconds = restTimeSeconds
        self.notes = notes
        self.createdAt = createdAt
    }
}






