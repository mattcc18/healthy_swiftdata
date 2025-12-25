//
//  MetricsCalculator.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 25/12/2025.
//

import Foundation

struct MetricsCalculator {
    static func totalWorkouts(_ workouts: [WorkoutHistory]) -> Int {
        workouts.count
    }
    
    static func totalExerciseTime(_ workouts: [WorkoutHistory]) -> Int {
        workouts.compactMap { $0.durationSeconds }.reduce(0, +)
    }
    
    static func averageWorkoutDuration(_ workouts: [WorkoutHistory]) -> Int? {
        let durations = workouts.compactMap { $0.durationSeconds }
        guard !durations.isEmpty else { return nil }
        return durations.reduce(0, +) / durations.count
    }
    
    static func workoutsThisWeek(_ workouts: [WorkoutHistory]) -> Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return workouts.filter { $0.completedAt >= weekAgo }.count
    }
    
    static func mostUsedExercise(_ workouts: [WorkoutHistory]) -> String? {
        var exerciseCounts: [String: Int] = [:]
        
        for workout in workouts {
            guard let entries = workout.entries else { continue }
            for entry in entries {
                let exerciseName = entry.exerciseName
                exerciseCounts[exerciseName, default: 0] += 1
            }
        }
        
        return exerciseCounts.max(by: { $0.value < $1.value })?.key
    }
    
    static func bodyWeightTrend(current: BodyWeightEntry?, previous: BodyWeightEntry?) -> MetricCard.MetricTrend? {
        guard let current = current, let previous = previous else {
            return nil
        }
        
        // Convert both to same unit for comparison (use current unit)
        let previousWeightInCurrentUnit: Double
        if current.unit == previous.unit {
            previousWeightInCurrentUnit = previous.weight
        } else if current.unit == "kg" && previous.unit == "lbs" {
            previousWeightInCurrentUnit = previous.weight * 0.453592
        } else {
            previousWeightInCurrentUnit = previous.weight * 2.20462
        }
        
        let change = current.weight - previousWeightInCurrentUnit
        let percentage = (change / previousWeightInCurrentUnit) * 100
        
        let direction: MetricCard.MetricTrend.TrendDirection
        if abs(change) < 0.1 {
            direction = .neutral
        } else if change > 0 {
            direction = .up
        } else {
            direction = .down
        }
        
        return MetricCard.MetricTrend(direction: direction, percentage: abs(percentage))
    }
    
    static func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    static func formatAverageDuration(_ seconds: Int?) -> String {
        guard let seconds = seconds else {
            return "N/A"
        }
        let minutes = seconds / 60
        return "\(minutes)m"
    }
}

