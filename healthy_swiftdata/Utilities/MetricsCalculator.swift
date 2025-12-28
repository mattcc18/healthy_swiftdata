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
    
    /// Calculate weekly average body weight from last 7 days
    static func weeklyAverageBodyWeight(from entries: [BodyWeightEntry]) -> Double? {
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        
        let weekEntries = entries.filter { $0.recordedAt >= weekAgo }
        guard !weekEntries.isEmpty else { return nil }
        
        // Convert all to kg for averaging
        let weightsInKg = weekEntries.map { entry in
            entry.unit == "kg" ? entry.weight : entry.weight * 0.453592
        }
        
        let average = weightsInKg.reduce(0, +) / Double(weightsInKg.count)
        return average
    }
    
    /// Calculate weekly average workouts from last 7 days
    static func weeklyAverageWorkouts(from workouts: [WorkoutHistory]) -> Double {
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        
        let weekWorkouts = workouts.filter { $0.completedAt >= weekAgo }
        return Double(weekWorkouts.count) / 7.0 // Average per day
    }
    
    /// Count stretching workouts in the last 7 days
    static func stretchingWorkoutsThisWeek(from workouts: [WorkoutHistory]) -> Int {
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        
        return workouts.filter { workout in
            workout.completedAt >= weekAgo &&
            workout.workoutType == "stretching"
        }.count
    }
    
    /// Get chart data for stretching workouts per day (last 7 days)
    static func stretchingWorkoutsChartData(from workouts: [WorkoutHistory]) -> [ChartDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        var dailyData: [Date: Int] = [:]
        
        // Count stretching workouts per day
        for workout in workouts {
            guard workout.workoutType == "stretching" else { continue }
            let dayStart = calendar.startOfDay(for: workout.completedAt)
            dailyData[dayStart, default: 0] += 1
        }
        
        // Get last 7 days (in reverse order to sort correctly)
        var chartData: [ChartDataPoint] = []
        for dayOffset in (0..<7).reversed() {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) {
                let dayStart = calendar.startOfDay(for: date)
                let count = dailyData[dayStart] ?? 0
                chartData.append(ChartDataPoint(date: dayStart, value: Double(count)))
            }
        }
        
        return chartData
    }
    
    /// Calculate average 1RM across all exercises
    static func average1RM(from workoutHistory: [WorkoutHistory]) -> Double? {
        var exercise1RMs: [String: Double] = [:]
        
        // Get unique exercises
        var uniqueExercises = Set<String>()
        for workout in workoutHistory {
            guard let entries = workout.entries else { continue }
            for entry in entries {
                uniqueExercises.insert(entry.exerciseName)
            }
        }
        
        // Get current 1RM for each exercise
        for exerciseName in uniqueExercises {
            if let current1RM = OneRepMaxCalculator.getCurrent1RM(for: exerciseName, from: workoutHistory) {
                exercise1RMs[exerciseName] = current1RM
            }
        }
        
        guard !exercise1RMs.isEmpty else { return nil }
        
        let total1RM = exercise1RMs.values.reduce(0, +)
        return total1RM / Double(exercise1RMs.count)
    }
    
    /// Calculate average 1RM increase (current vs 30 days ago)
    static func average1RMIncrease(from workoutHistory: [WorkoutHistory]) -> (current: Double, previous: Double, increase: Double, percentage: Double)? {
        let calendar = Calendar.current
        let now = Date()
        guard let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) else { return nil }
        
        // Split workouts into current and previous periods
        let currentWorkouts = workoutHistory.filter { $0.completedAt >= thirtyDaysAgo }
        let previousWorkouts = workoutHistory.filter { $0.completedAt < thirtyDaysAgo }
        
        guard let currentAvg = average1RM(from: currentWorkouts),
              let previousAvg = average1RM(from: previousWorkouts) else {
            return nil
        }
        
        let increase = currentAvg - previousAvg
        let percentage = (increase / previousAvg) * 100
        
        return (current: currentAvg, previous: previousAvg, increase: increase, percentage: percentage)
    }
    
    /// Get average 1RM trend
    static func average1RMTrend(from workoutHistory: [WorkoutHistory]) -> MetricCard.MetricTrend? {
        guard let data = average1RMIncrease(from: workoutHistory) else { return nil }
        
        let direction: MetricCard.MetricTrend.TrendDirection
        if abs(data.increase) < 0.1 {
            direction = .neutral
        } else if data.increase > 0 {
            direction = .up
        } else {
            direction = .down
        }
        
        return MetricCard.MetricTrend(direction: direction, percentage: abs(data.percentage))
    }
}





