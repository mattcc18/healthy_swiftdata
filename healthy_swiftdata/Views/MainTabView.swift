//
//  MainTabView.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 27/01/2025.
//

import SwiftUI
import SwiftData
import UIKit

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
            
            // Body Tab
            BodyMeasurementsView()
                .tabItem {
                    Label("Body", systemImage: "figure.arms.open")
                }
                .tag(4)
        }
        .tint(AppTheme.accentPrimary)
        .preferredColorScheme(.dark)
        .onAppear {
            // Configure tab bar appearance for glass morphism effect
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()
            
            // Create semi-transparent background with blur
            let backgroundColor = UIColor(AppTheme.cardSecondary).withAlphaComponent(0.7)
            appearance.backgroundColor = backgroundColor
            appearance.shadowColor = .clear
            
            // Configure item appearance
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(AppTheme.textTertiary)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(AppTheme.textTertiary)
            ]
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(AppTheme.accentPrimary)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(AppTheme.accentPrimary)
            ]
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [ExerciseTemplate.self, ActiveWorkout.self, WorkoutEntry.self, WorkoutSet.self, WorkoutHistory.self, WorkoutTemplate.self, TemplateExercise.self], inMemory: true)
}

