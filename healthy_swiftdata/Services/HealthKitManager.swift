//
//  HealthKitManager.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 25/12/2025.
//

import Foundation
import HealthKit
import Combine

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorized: Bool = false
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    
    // Health data types we want to read
    private let readTypes: Set<HKObjectType> = {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate),
              let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount),
              let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
              let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            return []
        }
        return [heartRateType, stepCountType, activeEnergyType, bodyMassType]
    }()
    
    // Health data types we want to write
    private let writeTypes: Set<HKSampleType> = {
        let workoutType = HKObjectType.workoutType()
        guard let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass),
              let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return []
        }
        return [workoutType, bodyMassType, activeEnergyType]
    }()
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // Check current authorization status
    private func checkAuthorizationStatus() {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        let status = healthStore.authorizationStatus(for: heartRateType)
        DispatchQueue.main.async {
            self.authorizationStatus = status
            // For read-only access, .sharingDenied can still mean read access is granted
            // We'll actually test by trying to read data instead of relying on status alone
            // So we consider it "authorized" if status is not .notDetermined
            self.isAuthorized = status != .notDetermined
        }
    }
    
    // Request HealthKit authorization
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.healthDataNotAvailable
        }
        
        guard !readTypes.isEmpty else {
            throw HealthKitError.invalidDataTypes
        }
        
        try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
        
        // Update authorization status
        checkAuthorizationStatus()
    }
    
    // Get most recent heart rate reading
    func getMostRecentHeartRate() async throws -> Double? {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            return nil
        }
        
        // Don't check authorization status here - let the query fail naturally if access is denied
        // This is because .sharingDenied can still allow read access
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    // Check if it's an authorization error
                    let nsError = error as NSError
                    if nsError.domain == "com.apple.healthkit" && nsError.code == 4 {
                        continuation.resume(throwing: HealthKitError.authorizationDenied)
                        return
                    }
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let samples = samples as? [HKQuantitySample],
                      let mostRecent = samples.first else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                let result = mostRecent.quantity.doubleValue(for: heartRateUnit)
                continuation.resume(returning: result)
            }
            
            healthStore.execute(query)
        }
    }
    
    // Get today's step count
    func getTodayStepCount() async throws -> Int? {
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return nil
        }
        
        // Don't check authorization status here - let the query fail naturally if access is denied
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        // Use .strictEndDate to include all samples up to now (not just before startOfDay)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: [.strictStartDate, .strictEndDate])
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepCountType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    // Check if it's an authorization error
                    let nsError = error as NSError
                    if nsError.domain == "com.apple.healthkit" && nsError.code == 4 {
                        continuation.resume(throwing: HealthKitError.authorizationDenied)
                        return
                    }
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let sum = statistics?.sumQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let stepCount = Int(sum.doubleValue(for: HKUnit.count()))
                continuation.resume(returning: stepCount)
            }
            
            healthStore.execute(query)
        }
    }
    
    // Get today's active energy (calories)
    func getTodayActiveEnergy() async throws -> Double? {
        guard let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return nil
        }
        
        // Check authorization status first
        let authStatus = healthStore.authorizationStatus(for: activeEnergyType)
        if authStatus == .notDetermined {
            throw HealthKitError.authorizationDenied
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: activeEnergyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    // Check if it's an authorization error
                    let nsError = error as NSError
                    if nsError.domain == "com.apple.healthkit" && nsError.code == 4 {
                        continuation.resume(throwing: HealthKitError.authorizationDenied)
                        return
                    }
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let sum = statistics?.sumQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let calories = sum.doubleValue(for: HKUnit.kilocalorie())
                continuation.resume(returning: calories)
            }
            
            healthStore.execute(query)
        }
    }
    
    // Get heart rate data for a date range (for charts)
    func getHeartRateData(from startDate: Date, to endDate: Date) async throws -> [(Date, Double)] {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            return []
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)
        
        return try await withCheckedThrowingContinuation { continuation in
            var results: [(Date, Double)] = []
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let samples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                results = samples.map { sample in
                    let value = sample.quantity.doubleValue(for: heartRateUnit)
                    return (sample.endDate, value)
                }
                
                continuation.resume(returning: results)
            }
            
            healthStore.execute(query)
        }
    }
    
    // Get step count data for a date range (for charts)
    func getStepCountData(from startDate: Date, to endDate: Date) async throws -> [(Date, Int)] {
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return []
        }
        
        let calendar = Calendar.current
        let startOfRange = calendar.startOfDay(for: startDate)
        let endOfRange = calendar.startOfDay(for: endDate)
        
        // Use HKStatisticsCollectionQuery for efficient daily aggregation
        let anchorDate = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
        let interval = DateComponents(day: 1)
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfRange, end: endOfRange, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: stepCountType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: anchorDate,
                intervalComponents: interval
            )
            
            query.initialResultsHandler = { _, results, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let results = results else {
                    continuation.resume(returning: [])
                    return
                }
                
                var dailyResults: [(Date, Int)] = []
                results.enumerateStatistics(from: startOfRange, to: endOfRange) { statistics, _ in
                    if let sum = statistics.sumQuantity() {
                        let steps = Int(sum.doubleValue(for: HKUnit.count()))
                        dailyResults.append((statistics.startDate, steps))
                    } else {
                        dailyResults.append((statistics.startDate, 0))
                    }
                }
                
                continuation.resume(returning: dailyResults)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Write Methods
    
    // Save workout to HealthKit
    func saveWorkout(
        startDate: Date,
        endDate: Date,
        duration: TimeInterval,
        totalEnergyBurned: Double?,
        workoutType: HKWorkoutActivityType = .traditionalStrengthTraining
    ) async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.healthDataNotAvailable
        }
        
        // Check write authorization
        let workoutTypeObj = HKObjectType.workoutType()
        let authStatus = healthStore.authorizationStatus(for: workoutTypeObj)
        if authStatus != .sharingAuthorized {
            // Request authorization if not already granted
            try await requestAuthorization()
        }
        
        // Create workout metadata
        let metadata: [String: Any] = [:]
        
        // Create energy burned sample if available
        var energySamples: [HKQuantitySample] = []
        if let energy = totalEnergyBurned, energy > 0 {
            guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
                throw HealthKitError.invalidDataTypes
            }
            let energyQuantity = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: energy)
            let energySample = HKQuantitySample(
                type: energyType,
                quantity: energyQuantity,
                start: startDate,
                end: endDate
            )
            energySamples.append(energySample)
        }
        
        // Create HKWorkout
        // Note: Using deprecated initializer for compatibility. HKWorkoutBuilder requires iOS 17+ and is more complex.
        // This deprecation warning can be safely ignored for now.
        // swiftlint:disable:next deprecated
        // Note: HKWorkout initializer is deprecated in iOS 17.0, but we're using it for compatibility.
        let workout = HKWorkout(
            activityType: workoutType,
            start: startDate,
            end: endDate,
            duration: duration,
            totalEnergyBurned: totalEnergyBurned.map { HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: $0) },
            totalDistance: nil,
            metadata: metadata.isEmpty ? nil : metadata
        )
        
        // Save workout using completion handler
        try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<Void, Error>) in
            guard let self = self else {
                continuation.resume(throwing: HealthKitError.healthDataNotAvailable)
                return
            }
            
            self.healthStore.save(workout) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                if !success {
                    continuation.resume(throwing: HealthKitError.invalidDataTypes)
                    return
                }
                
                // Save energy samples if available
                if !energySamples.isEmpty {
                    self.healthStore.save(energySamples) { success, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                            return
                        }
                        continuation.resume()
                    }
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    // Save body weight to HealthKit
    func saveBodyWeight(weight: Double, unit: String, date: Date) async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.healthDataNotAvailable
        }
        
        guard let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            throw HealthKitError.invalidDataTypes
        }
        
        // Check write authorization
        let authStatus = healthStore.authorizationStatus(for: bodyMassType)
        if authStatus != .sharingAuthorized {
            // Request authorization if not already granted
            try await requestAuthorization()
        }
        
        // Convert to kg if needed
        let weightInKg: Double
        if unit.lowercased() == "lbs" {
            weightInKg = weight * 0.453592 // Convert lbs to kg
        } else {
            weightInKg = weight
        }
        
        let quantity = HKQuantity(unit: HKUnit.gramUnit(with: .kilo), doubleValue: weightInKg)
        let sample = HKQuantitySample(
            type: bodyMassType,
            quantity: quantity,
            start: date,
            end: date
        )
        
        // Save using completion handler
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.save(sample) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                if !success {
                    continuation.resume(throwing: HealthKitError.invalidDataTypes)
                    return
                }
                
                continuation.resume()
            }
        }
    }
    
    // Get body weight data from HealthKit (for syncing)
    func getBodyWeightData(from startDate: Date, to endDate: Date) async throws -> [(Date, Double)] {
        guard let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            return []
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: bodyMassType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let samples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let kgUnit = HKUnit.gramUnit(with: .kilo)
                let results = samples.map { sample in
                    let value = sample.quantity.doubleValue(for: kgUnit)
                    return (sample.endDate, value)
                }
                
                continuation.resume(returning: results)
            }
            
            healthStore.execute(query)
        }
    }
}

enum HealthKitError: LocalizedError {
    case healthDataNotAvailable
    case invalidDataTypes
    case authorizationDenied
    
    var errorDescription: String? {
        switch self {
        case .healthDataNotAvailable:
            return "Health data is not available on this device"
        case .invalidDataTypes:
            return "Invalid HealthKit data types"
        case .authorizationDenied:
            return "HealthKit authorization was denied"
        }
    }
}

