//
//  WorkoutSet.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 27/01/2025.
//

import Foundation
import SwiftData

@Model
final class WorkoutSet {
    var id: UUID
    var setNumber: Int
    var reps: Int?
    var weight: Double?
    var restTime: Int? // in seconds
    var completedAt: Date?
    var createdAt: Date
    
    // Relationship to WorkoutEntry
    var workoutEntry: WorkoutEntry?
    
    init(
        id: UUID = UUID(),
        setNumber: Int,
        reps: Int? = nil,
        weight: Double? = nil,
        restTime: Int? = nil,
        completedAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.setNumber = setNumber
        self.reps = reps
        self.weight = weight
        self.restTime = restTime
        self.completedAt = completedAt
        self.createdAt = createdAt
    }
}

