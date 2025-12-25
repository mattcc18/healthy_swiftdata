//
//  DataSeeder.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 27/01/2025.
//

import Foundation
import SwiftData

struct DataSeeder {
    static func seedExerciseTemplates(modelContext: ModelContext) {
        // Check if data already exists
        let descriptor = FetchDescriptor<ExerciseTemplate>()
        if let count = try? modelContext.fetchCount(descriptor), count > 0 {
            return // Data already seeded
        }
        
        // Strength Exercises
        let strengthExercises: [(String, [String], String, String)] = [
            ("Bench Press", ["Chest", "Triceps", "Shoulders"], "figure.strengthtraining.traditional", "#FF6B6B"),
            ("Squat", ["Quadriceps", "Glutes", "Hamstrings"], "figure.run", "#4ECDC4"),
            ("Deadlift", ["Hamstrings", "Glutes", "Back"], "figure.strengthtraining.traditional", "#45B7D1"),
            ("Overhead Press", ["Shoulders", "Triceps"], "figure.strengthtraining.traditional", "#FFA07A"),
            ("Barbell Row", ["Back", "Biceps"], "figure.strengthtraining.traditional", "#98D8C8"),
            ("Pull-up", ["Back", "Biceps"], "figure.strengthtraining.traditional", "#F7DC6F"),
            ("Dumbbell Curl", ["Biceps"], "figure.strengthtraining.traditional", "#BB8FCE"),
            ("Tricep Extension", ["Triceps"], "figure.strengthtraining.traditional", "#85C1E2"),
            ("Lunges", ["Quadriceps", "Glutes"], "figure.run", "#F8B739"),
            ("Leg Press", ["Quadriceps", "Glutes"], "figure.run", "#52BE80"),
            ("Chest Fly", ["Chest"], "figure.strengthtraining.traditional", "#EC7063"),
            ("Lat Pulldown", ["Back", "Biceps"], "figure.strengthtraining.traditional", "#5DADE2"),
            ("Shoulder Raise", ["Shoulders"], "figure.strengthtraining.traditional", "#F1948A"),
            ("Bicep Hammer Curl", ["Biceps", "Forearms"], "figure.strengthtraining.traditional", "#85C1E2"),
            ("Leg Curl", ["Hamstrings"], "figure.run", "#52BE80"),
            ("Leg Extension", ["Quadriceps"], "figure.run", "#F8B739"),
            ("Calf Raise", ["Calves"], "figure.run", "#52BE80"),
            ("Plank", ["Core", "Shoulders"], "figure.core.training", "#F7DC6F"),
            ("Russian Twist", ["Core"], "figure.core.training", "#F1948A"),
            ("Cable Crossover", ["Chest"], "figure.strengthtraining.traditional", "#FF6B6B")
        ]
        
        for (name, muscleGroups, icon, iconColor) in strengthExercises {
            let exercise = ExerciseTemplate(
                name: name,
                category: "Strength",
                muscleGroups: muscleGroups,
                icon: icon,
                iconColor: iconColor
            )
            modelContext.insert(exercise)
        }
        
        // Cardio Exercises
        let cardioExercises: [(String, [String], String, String)] = [
            ("Running", ["Cardio", "Legs"], "figure.run", "#E74C3C"),
            ("Cycling", ["Cardio", "Legs"], "bicycle", "#3498DB"),
            ("Swimming", ["Cardio", "Full Body"], "figure.strengthtraining.traditional", "#1ABC9C"),
            ("Rowing", ["Cardio", "Back", "Legs"], "figure.strengthtraining.traditional", "#9B59B6"),
            ("Jump Rope", ["Cardio", "Calves"], "figure.strengthtraining.traditional", "#E67E22"),
            ("Elliptical", ["Cardio", "Legs"], "figure.run", "#3498DB"),
            ("Treadmill", ["Cardio", "Legs"], "figure.run", "#E74C3C"),
            ("Burpees", ["Cardio", "Full Body"], "figure.strengthtraining.traditional", "#E67E22"),
            ("Mountain Climbers", ["Cardio", "Core"], "figure.strengthtraining.traditional", "#F39C12"),
            ("High Knees", ["Cardio", "Legs"], "figure.run", "#E74C3C")
        ]
        
        for (name, muscleGroups, icon, iconColor) in cardioExercises {
            let exercise = ExerciseTemplate(
                name: name,
                category: "Cardio",
                muscleGroups: muscleGroups,
                icon: icon,
                iconColor: iconColor
            )
            modelContext.insert(exercise)
        }
        
        // Flexibility Exercises
        let flexibilityExercises: [(String, [String], String, String)] = [
            ("Yoga", ["Flexibility", "Full Body"], "figure.strengthtraining.traditional", "#9B59B6"),
            ("Stretching", ["Flexibility", "Full Body"], "figure.strengthtraining.traditional", "#3498DB"),
            ("Pilates", ["Flexibility", "Core"], "figure.strengthtraining.traditional", "#1ABC9C"),
            ("Hamstring Stretch", ["Flexibility", "Hamstrings"], "figure.strengthtraining.traditional", "#3498DB"),
            ("Hip Flexor Stretch", ["Flexibility", "Hip Flexors"], "figure.strengthtraining.traditional", "#9B59B6"),
            ("Shoulder Stretch", ["Flexibility", "Shoulders"], "figure.strengthtraining.traditional", "#3498DB"),
            ("Quad Stretch", ["Flexibility", "Quadriceps"], "figure.strengthtraining.traditional", "#1ABC9C"),
            ("Cat-Cow Stretch", ["Flexibility", "Back", "Core"], "figure.strengthtraining.traditional", "#9B59B6"),
            ("Child's Pose", ["Flexibility", "Back"], "figure.strengthtraining.traditional", "#3498DB"),
            ("Downward Dog", ["Flexibility", "Full Body"], "figure.strengthtraining.traditional", "#1ABC9C")
        ]
        
        for (name, muscleGroups, icon, iconColor) in flexibilityExercises {
            let exercise = ExerciseTemplate(
                name: name,
                category: "Flexibility",
                muscleGroups: muscleGroups,
                icon: icon,
                iconColor: iconColor
            )
            modelContext.insert(exercise)
        }
        
        // Other Exercises
        let otherExercises: [(String, [String], String, String)] = [
            ("Walking", ["Cardio", "Legs"], "figure.walk", "#95A5A6"),
            ("Hiking", ["Cardio", "Legs"], "figure.walk.motion", "#7F8C8D"),
            ("Rock Climbing", ["Full Body", "Back", "Arms"], "figure.strengthtraining.traditional", "#34495E"),
            ("Dancing", ["Cardio", "Full Body"], "figure.dance", "#E91E63"),
            ("Tennis", ["Cardio", "Arms", "Legs"], "figure.tennis", "#4CAF50"),
            ("Basketball", ["Cardio", "Full Body"], "figure.basketball", "#FF9800"),
            ("Boxing", ["Cardio", "Arms", "Core"], "figure.boxing", "#F44336"),
            ("Martial Arts", ["Full Body", "Cardio"], "figure.strengthtraining.traditional", "#9C27B0")
        ]
        
        for (name, muscleGroups, icon, iconColor) in otherExercises {
            let exercise = ExerciseTemplate(
                name: name,
                category: "Other",
                muscleGroups: muscleGroups,
                icon: icon,
                iconColor: iconColor
            )
            modelContext.insert(exercise)
        }
        
        // Save all exercises
        try? modelContext.save()
    }
    
    static func seedWorkoutTemplates(modelContext: ModelContext) {
        // Check if templates already exist
        let descriptor = FetchDescriptor<WorkoutTemplate>()
        if let count = try? modelContext.fetchCount(descriptor), count > 0 {
            return // Templates already seeded
        }
        
        // Fetch exercise templates by name
        let exerciseDescriptor = FetchDescriptor<ExerciseTemplate>()
        let allExercises = (try? modelContext.fetch(exerciseDescriptor)) ?? []
        
        func findExercise(byName name: String) -> ExerciseTemplate? {
            return allExercises.first { $0.name == name }
        }
        
        // Push Day Template
        if let benchPress = findExercise(byName: "Bench Press"),
           let overheadPress = findExercise(byName: "Overhead Press"),
           let tricepExtension = findExercise(byName: "Tricep Extension") {
            
            let pushDayTemplate = WorkoutTemplate(
                name: "Push Day",
                notes: "Chest, shoulders, and triceps workout"
            )
            modelContext.insert(pushDayTemplate)
            
            let pushDayExercises: [(ExerciseTemplate, Int, Int, Int)] = [
                (benchPress, 3, 8, 90),
                (overheadPress, 3, 8, 90),
                (tricepExtension, 3, 8, 90)
            ]
            
            for (index, (exercise, sets, reps, rest)) in pushDayExercises.enumerated() {
                let templateExercise = TemplateExercise(
                    exerciseTemplate: exercise,
                    exerciseName: exercise.name,
                    order: index,
                    targetReps: reps,
                    numberOfSets: sets,
                    restTimeSeconds: rest
                )
                templateExercise.workoutTemplate = pushDayTemplate
                modelContext.insert(templateExercise)
            }
        }
        
        // Pull Day Template
        if let pullUp = findExercise(byName: "Pull-up"),
           let barbellRow = findExercise(byName: "Barbell Row"),
           let bicepCurl = findExercise(byName: "Dumbbell Curl") {
            
            let pullDayTemplate = WorkoutTemplate(
                name: "Pull Day",
                notes: "Back and biceps workout"
            )
            modelContext.insert(pullDayTemplate)
            
            let pullDayExercises: [(ExerciseTemplate, Int, Int, Int)] = [
                (pullUp, 3, 8, 90),
                (barbellRow, 3, 8, 90),
                (bicepCurl, 3, 8, 90)
            ]
            
            for (index, (exercise, sets, reps, rest)) in pullDayExercises.enumerated() {
                let templateExercise = TemplateExercise(
                    exerciseTemplate: exercise,
                    exerciseName: exercise.name,
                    order: index,
                    targetReps: reps,
                    numberOfSets: sets,
                    restTimeSeconds: rest
                )
                templateExercise.workoutTemplate = pullDayTemplate
                modelContext.insert(templateExercise)
            }
        }
        
        // Leg Day Template
        if let squat = findExercise(byName: "Squat"),
           let deadlift = findExercise(byName: "Deadlift"),
           let lunges = findExercise(byName: "Lunges") {
            
            let legDayTemplate = WorkoutTemplate(
                name: "Leg Day",
                notes: "Legs and glutes workout"
            )
            modelContext.insert(legDayTemplate)
            
            let legDayExercises: [(ExerciseTemplate, Int, Int, Int)] = [
                (squat, 3, 8, 90),
                (deadlift, 3, 8, 90),
                (lunges, 3, 8, 90)
            ]
            
            for (index, (exercise, sets, reps, rest)) in legDayExercises.enumerated() {
                let templateExercise = TemplateExercise(
                    exerciseTemplate: exercise,
                    exerciseName: exercise.name,
                    order: index,
                    targetReps: reps,
                    numberOfSets: sets,
                    restTimeSeconds: rest
                )
                templateExercise.workoutTemplate = legDayTemplate
                modelContext.insert(templateExercise)
            }
        }
        
        // Save all templates
        try? modelContext.save()
    }
}

