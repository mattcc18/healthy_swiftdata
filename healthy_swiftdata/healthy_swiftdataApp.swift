//
//  healthy_swiftdataApp.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 24/12/2025.
//

import SwiftUI
import SwiftData

@main
struct healthy_swiftdataApp: App {
    // SwiftData container configuration
    let container: ModelContainer
    
    init() {
        // Configure SwiftData schema
        let schema = Schema([
            ExerciseTemplate.self,
            ActiveWorkout.self,
            WorkoutEntry.self,
            WorkoutSet.self,
            WorkoutHistory.self,
            WorkoutTemplate.self,
            TemplateExercise.self,
            BodyWeightEntry.self,
            BodyMeasurement.self
        ])
        
        // Configure model container with in-memory storage for development
        // Change to .persistentContainer for production
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
                .onAppear {
                    // Request notification permissions on app launch
                    Task {
                        _ = try? await NotificationManager.shared.requestAuthorization()
                    }
                }
        }
        .modelContainer(container)
    }
}
