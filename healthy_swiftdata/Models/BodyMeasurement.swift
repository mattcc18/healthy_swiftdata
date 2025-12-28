//
//  BodyMeasurement.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 28/12/2025.
//

import Foundation
import SwiftData

@Model
final class BodyMeasurement {
    var id: UUID
    var measurementType: String // "neck", "height", "waist", "chest", "armLeft", "armRight", "legLeft", "legRight", "hip", "bodyFat"
    var value: Double
    var unit: String // "cm" or "inches"
    var recordedAt: Date
    var notes: String?
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        measurementType: String,
        value: Double,
        unit: String = "cm",
        recordedAt: Date = Date(),
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.measurementType = measurementType
        self.value = value
        self.unit = unit
        self.recordedAt = recordedAt
        self.notes = notes
        self.createdAt = createdAt
    }
}


