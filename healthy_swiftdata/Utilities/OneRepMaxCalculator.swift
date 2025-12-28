//
//  OneRepMaxCalculator.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 27/01/2025.
//

import Foundation
import SwiftData

struct OneRepMaxCalculator {
    /// Calculate 1RM using Epley formula: weight * (1 + reps/30)
    static func calculate1RM(weight: Double, reps: Int) -> Double {
        guard reps > 0, weight > 0 else { return 0 }
        return weight * (1 + Double(reps) / 30.0)
    }
    
    /// Get 1RM progression data for an exercise from workout history
    static func get1RMProgression(
        for exerciseName: String,
        from workoutHistory: [WorkoutHistory]
    ) -> [OneRepMaxDataPoint] {
        var dataPoints: [OneRepMaxDataPoint] = []
        
        // Iterate through workout history
        for workout in workoutHistory.sorted(by: { $0.completedAt < $1.completedAt }) {
            guard let entries = workout.entries else { continue }
            
            // Find entries matching this exercise name
            for entry in entries where entry.exerciseName == exerciseName {
                guard let sets = entry.sets else { continue }
                
                // Find the best set (highest 1RM) for this workout
                var best1RM: Double = 0
                var bestDate: Date = workout.completedAt
                
                for set in sets {
                    guard let weight = set.weight,
                          let reps = set.reps,
                          let completedAt = set.completedAt else { continue }
                    
                    let oneRM = calculate1RM(weight: weight, reps: reps)
                    if oneRM > best1RM {
                        best1RM = oneRM
                        bestDate = completedAt
                    }
                }
                
                // Only add if we found a valid 1RM
                if best1RM > 0 {
                    dataPoints.append(OneRepMaxDataPoint(
                        date: bestDate,
                        oneRM: best1RM
                    ))
                }
            }
        }
        
        // Sort by date and remove duplicates (keep highest 1RM for same day)
        let groupedByDate = Dictionary(grouping: dataPoints) { Calendar.current.startOfDay(for: $0.date) }
        let deduplicated = groupedByDate.values.compactMap { points in
            points.max(by: { $0.oneRM < $1.oneRM })
        }
        
        return deduplicated.sorted(by: { $0.date < $1.date })
    }
    
    /// Get current estimated 1RM (most recent)
    static func getCurrent1RM(
        for exerciseName: String,
        from workoutHistory: [WorkoutHistory]
    ) -> Double? {
        let progression = get1RMProgression(for: exerciseName, from: workoutHistory)
        return progression.last?.oneRM
    }
    
    /// Get top N exercises ranked by estimated 1RM
    static func getTopExercises(
        from workoutHistory: [WorkoutHistory],
        exerciseTemplates: [ExerciseTemplate]
    ) -> [TopExercise] {
        var exercise1RMs: [String: Double] = [:]
        
        // Filter to only favorite exercises
        let favoriteExercises = exerciseTemplates.filter { $0.isFavorite == true }
        guard !favoriteExercises.isEmpty else { return [] }
        
        let favoriteExerciseNames = Set(favoriteExercises.map { $0.name })
        
        // Calculate current 1RM for each favorite exercise
        var uniqueExercises = Set<String>()
        for workout in workoutHistory {
            guard let entries = workout.entries else { continue }
            for entry in entries {
                if favoriteExerciseNames.contains(entry.exerciseName) {
                    uniqueExercises.insert(entry.exerciseName)
                }
            }
        }
        
        // Get current 1RM for each favorite exercise
        for exerciseName in uniqueExercises {
            if let current1RM = getCurrent1RM(for: exerciseName, from: workoutHistory) {
                exercise1RMs[exerciseName] = current1RM
            }
        }
        
        // Sort by 1RM descending (no limit - show all favorites)
        let topExercises = exercise1RMs
            .sorted { $0.value > $1.value }
            .enumerated()
            .map { index, pair in
                TopExercise(
                    name: pair.key,
                    estimated1RM: pair.value,
                    rank: index + 1
                )
            }
        
        return Array(topExercises)
    }
}

struct TopExercise: Identifiable {
    let id = UUID()
    let name: String
    let estimated1RM: Double
    let rank: Int
}

struct OneRepMaxDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let oneRM: Double
}

