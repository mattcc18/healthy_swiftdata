//
//  ChartDataProcessor.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 25/12/2025.
//

import Foundation
import SwiftData

enum MetricType: Hashable {
    case totalWorkouts
    case bodyWeight
    case exerciseTime
    case workoutsThisWeek
    case heartRate
    case stepCount
    case activeEnergy
    case average1RM
    
    var displayName: String {
        switch self {
        case .totalWorkouts:
            return "Total Workouts"
        case .bodyWeight:
            return "Body Weight"
        case .exerciseTime:
            return "Exercise Time"
        case .workoutsThisWeek:
            return "Workouts This Week"
        case .heartRate:
            return "Heart Rate"
        case .stepCount:
            return "Steps"
        case .activeEnergy:
            return "Calories"
        case .average1RM:
            return "Average 1RM"
        }
    }
    
    var unit: String {
        switch self {
        case .totalWorkouts:
            return ""
        case .bodyWeight:
            return "kg"
        case .exerciseTime:
            return "min"
        case .workoutsThisWeek:
            return ""
        case .heartRate:
            return "bpm"
        case .stepCount:
            return "steps"
        case .activeEnergy:
            return "kcal"
        case .average1RM:
            return "kg"
        }
    }
}

struct ChartDataProcessor {
    // Aggregate workout history data by time period
    static func aggregateWorkouts(history: [WorkoutHistory], period: TimePeriod) -> [ChartDataPoint] {
        let calendar = Calendar.current
        var aggregated: [Date: Double] = [:]
        
        for workout in history {
            let completedAt = workout.completedAt
            let keyDate = period.startDate(for: completedAt, calendar: calendar)
            aggregated[keyDate, default: 0] += 1
        }
        
        return aggregated.map { ChartDataPoint(date: $0.key, value: $0.value) }
            .sorted { $0.date < $1.date }
    }
    
    // Aggregate body weight entries by time period
    static func aggregateBodyWeight(entries: [BodyWeightEntry], period: TimePeriod) -> [ChartDataPoint] {
        let calendar = Calendar.current
        var aggregated: [Date: (sum: Double, count: Int)] = [:]
        
        for entry in entries {
            let keyDate = period.startDate(for: entry.recordedAt, calendar: calendar)
            let existing = aggregated[keyDate, default: (sum: 0.0, count: 0)]
            aggregated[keyDate] = (sum: existing.sum + entry.weight, count: existing.count + 1)
        }
        
        return aggregated.map { date, data in
            let average = data.count > 0 ? data.sum / Double(data.count) : 0
            return ChartDataPoint(date: date, value: average)
        }
        .sorted { $0.date < $1.date }
    }
    
    // Aggregate exercise time by time period
    static func aggregateExerciseTime(history: [WorkoutHistory], period: TimePeriod) -> [ChartDataPoint] {
        let calendar = Calendar.current
        var aggregated: [Date: Double] = [:]
        
        for workout in history {
            let completedAt = workout.completedAt
            guard let durationSeconds = workout.durationSeconds else { continue }
            
            let keyDate = period.startDate(for: completedAt, calendar: calendar)
            let minutes = Double(durationSeconds) / 60.0
            aggregated[keyDate, default: 0] += minutes
        }
        
        return aggregated.map { ChartDataPoint(date: $0.key, value: $0.value) }
            .sorted { $0.date < $1.date }
    }
    
    // Aggregate workouts this week (rolling 7-day window)
    static func aggregateWorkoutsThisWeek(history: [WorkoutHistory], period: TimePeriod) -> [ChartDataPoint] {
        let calendar = Calendar.current
        var aggregated: [Date: Double] = [:]
        
        for workout in history {
            let completedAt = workout.completedAt
            let keyDate = period.startDate(for: completedAt, calendar: calendar)
            aggregated[keyDate, default: 0] += 1
        }
        
        return aggregated.map { ChartDataPoint(date: $0.key, value: $0.value) }
            .sorted { $0.date < $1.date }
    }
    
    // Process HealthKit heart rate data
    static func processHeartRateData(_ data: [(Date, Double)]) -> [ChartDataPoint] {
        return data.map { ChartDataPoint(date: $0.0, value: $0.1) }
            .sorted { $0.date < $1.date }
    }
    
    // Process HealthKit step count data
    static func processStepCountData(_ data: [(Date, Int)]) -> [ChartDataPoint] {
        return data.map { ChartDataPoint(date: $0.0, value: Double($0.1)) }
            .sorted { $0.date < $1.date }
    }
}

enum TimePeriod {
    case day
    case week
    case month
    case sixMonths
    case year
    
    var displayName: String {
        switch self {
        case .day:
            return "Day"
        case .week:
            return "Week"
        case .month:
            return "Month"
        case .sixMonths:
            return "6 Months"
        case .year:
            return "Year"
        }
    }
    
    var shortDisplayName: String {
        switch self {
        case .day:
            return "D"
        case .week:
            return "W"
        case .month:
            return "M"
        case .sixMonths:
            return "6M"
        case .year:
            return "Y"
        }
    }
    
    func startDate(for date: Date, calendar: Calendar) -> Date {
        switch self {
        case .day:
            return calendar.startOfDay(for: date)
        case .week:
            return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) ?? date
        case .month:
            let components = calendar.dateComponents([.year, .month], from: date)
            return calendar.date(from: components) ?? date
        case .sixMonths:
            // Group by month, but show last 6 months
            let components = calendar.dateComponents([.year, .month], from: date)
            return calendar.date(from: components) ?? date
        case .year:
            let components = calendar.dateComponents([.year], from: date)
            return calendar.date(from: components) ?? date
        }
    }
    
    func dateRange(endingAt endDate: Date = Date(), calendar: Calendar = Calendar.current) -> (start: Date, end: Date) {
        let end = calendar.startOfDay(for: endDate)
        let start: Date
        
        switch self {
        case .day:
            start = end
        case .week:
            start = calendar.date(byAdding: .day, value: -7, to: end) ?? end
        case .month:
            start = calendar.date(byAdding: .month, value: -1, to: end) ?? end
        case .sixMonths:
            start = calendar.date(byAdding: .month, value: -6, to: end) ?? end
        case .year:
            start = calendar.date(byAdding: .year, value: -1, to: end) ?? end
        }
        
        return (start: start, end: end)
    }
}

