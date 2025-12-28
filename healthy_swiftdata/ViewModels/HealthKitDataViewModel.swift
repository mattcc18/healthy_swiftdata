//
//  HealthKitDataViewModel.swift
//  healthy_swiftdata
//
//  Extracted from ContentView.swift for better separation of concerns
//

import SwiftUI
import Combine
import HealthKit

@MainActor
class HealthKitDataViewModel: ObservableObject {
    @Published var heartRate: Double? = nil
    @Published var stepCount: Int? = nil
    @Published var activeEnergy: Double? = nil
    @Published var healthKitError: String? = nil
    @Published var isLoadingHealthKit = false
    @Published var lastHealthKitRefresh: Date? = nil
    
    private let healthKitManager = HealthKitManager.shared
    
    var shouldRefresh: Bool {
        // Refresh if we've never refreshed, or if it's been more than 5 minutes
        guard let lastRefresh = lastHealthKitRefresh else { return true }
        let fiveMinutesAgo = Date().addingTimeInterval(-5 * 60)
        return lastRefresh < fiveMinutesAgo
    }
    
    func refreshHealthKitData() {
        guard HKHealthStore.isHealthDataAvailable() else {
            healthKitError = "Health data is not available on this device"
            isLoadingHealthKit = false
            return
        }
        
        isLoadingHealthKit = true
        healthKitError = nil
        
        Task {
            await refreshHealthKitDataAsync()
        }
    }
    
    func refreshHealthKitDataAsync() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            healthKitError = "Health data is not available on this device"
            isLoadingHealthKit = false
            return
        }
        
        isLoadingHealthKit = true
        healthKitError = nil
        
        do {
            // Request authorization if needed (this will prompt user if not determined)
            if healthKitManager.authorizationStatus == .notDetermined {
                try await healthKitManager.requestAuthorization()
            }
            
            // Try to fetch HealthKit data - if authorization was denied, the queries will fail
            // We'll catch the error and show a message
            async let heartRateTask = healthKitManager.getMostRecentHeartRate()
            async let stepCountTask = healthKitManager.getTodayStepCount()
            async let activeEnergyTask = healthKitManager.getTodayActiveEnergy()
            
            let (heartRateResult, stepCountResult, activeEnergyResult) = try await (heartRateTask, stepCountTask, activeEnergyTask)
            
            // Set values even if nil (no data available is different from error)
            self.heartRate = heartRateResult
            self.stepCount = stepCountResult
            self.activeEnergy = activeEnergyResult
            self.isLoadingHealthKit = false
            self.lastHealthKitRefresh = Date()
            // Clear any previous errors if we got here successfully
            self.healthKitError = nil
            
            // Debug: Print results to console
            print("HealthKit Data Loaded:")
            print("  Heart Rate: \(heartRateResult?.description ?? "nil")")
            print("  Step Count: \(stepCountResult?.description ?? "nil")")
            print("  Active Energy: \(activeEnergyResult?.description ?? "nil")")
        } catch {
            // Check if it's an authorization error
            if let hkError = error as? HealthKitError, hkError == .authorizationDenied {
                healthKitError = "HealthKit access denied. Please enable it in Settings > Privacy & Security > Health."
            } else {
                // Check if it's a HealthKit authorization error by error code
                let nsError = error as NSError
                if nsError.domain == "com.apple.healthkit" && nsError.code == 4 {
                    healthKitError = "HealthKit access denied. Please enable it in Settings > Privacy & Security > Health."
                } else {
                    // For other errors (like no data available), don't show error message
                    // Just silently fail - missing data is not an error
                    healthKitError = nil
                    print("HealthKit query error (non-critical): \(error.localizedDescription)")
                }
            }
            isLoadingHealthKit = false
            lastHealthKitRefresh = Date() // Still update timestamp to avoid constant retries
        }
    }
}

