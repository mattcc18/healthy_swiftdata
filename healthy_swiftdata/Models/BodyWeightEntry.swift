//
//  BodyWeightEntry.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 25/12/2025.
//

import Foundation
import SwiftData

@Model
final class BodyWeightEntry {
    var id: UUID
    var weight: Double
    var unit: String // "kg" or "lbs"
    var recordedAt: Date
    var notes: String?
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        weight: Double,
        unit: String = "kg",
        recordedAt: Date = Date(),
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.weight = weight
        self.unit = unit
        self.recordedAt = recordedAt
        self.notes = notes
        self.createdAt = createdAt
    }
}

