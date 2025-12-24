//
//  MainTabView.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 27/01/2025.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home/Overview Tab
            ContentView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            // Active Workout Tab
            ActiveWorkoutView()
                .tabItem {
                    Label("Workout", systemImage: "figure.strengthtraining.traditional")
                }
                .tag(1)
            
            // History Tab
            WorkoutHistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(2)
            
            // Exercises Tab
            ExercisesView()
                .tabItem {
                    Label("Exercises", systemImage: "list.bullet")
                }
                .tag(3)
            
            // Templates Tab
            WorkoutTemplatesView()
                .tabItem {
                    Label("Templates", systemImage: "doc.text")
                }
                .tag(4)
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [ExerciseTemplate.self, ActiveWorkout.self, WorkoutEntry.self, WorkoutSet.self, WorkoutHistory.self, WorkoutTemplate.self, TemplateExercise.self], inMemory: true)
}

