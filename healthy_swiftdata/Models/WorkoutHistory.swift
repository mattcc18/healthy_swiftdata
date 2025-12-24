//
//  WorkoutHistory.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 27/01/2025.
//

import Foundation
import SwiftData

@Model
final class WorkoutHistory {
    var id: UUID
    var startedAt: Date
    var completedAt: Date
    var templateName: String?
    var notes: String?
    var durationSeconds: Int? // Calculated: completedAt - startedAt
    var totalVolume: Double? // Calculated: sum of (reps * weight) for all sets
    
    // Exercise entries (snapshot from active workout)
    @Relationship(deleteRule: .cascade) var entries: [WorkoutEntry]?
    
    // Sync status (for future backend integration)
    var isSynced: Bool
    var syncedAt: Date?
    
    init(
        id: UUID = UUID(),
        startedAt: Date,
        completedAt: Date,
        templateName: String? = nil,
        notes: String? = nil,
        durationSeconds: Int? = nil,
        totalVolume: Double? = nil,
        isSynced: Bool = false,
        syncedAt: Date? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.templateName = templateName
        self.notes = notes
        self.durationSeconds = durationSeconds
        self.totalVolume = totalVolume
        self.isSynced = isSynced
        self.syncedAt = syncedAt
    }
}

