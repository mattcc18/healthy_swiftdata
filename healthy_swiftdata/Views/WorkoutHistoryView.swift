//
//  WorkoutHistoryView.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 27/01/2025.
//

import SwiftUI
import SwiftData
import HealthKit

struct WorkoutHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        sort: \WorkoutHistory.completedAt,
        order: .reverse
    ) private var allWorkouts: [WorkoutHistory]
    
    var body: some View {
        NavigationStack {
            WorkoutCalendarView()
                .navigationTitle("Workout History")
        }
    }
    
}

struct WorkoutHistoryRow: View {
    let workout: WorkoutHistory
    let showDate: Bool
    @State private var averageHeartRate: Double? = nil
    @StateObject private var healthKitManager = HealthKitManager.shared
    
    init(workout: WorkoutHistory, showDate: Bool = true) {
        self.workout = workout
        self.showDate = showDate
    }
    
    var workoutType: WorkoutType? {
        workout.workoutType.flatMap { WorkoutType(rawValue: $0) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if showDate {
                    Text(workout.completedAt, style: .date)
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                }
                
                // Workout type tag
                if let type = workoutType {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(type.color)
                            .frame(width: 8, height: 8)
                        Text(type.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(type.color)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(type.color.opacity(0.15))
                    .cornerRadius(8)
                }
                
                Spacer()
                
                if let duration = workout.durationSeconds {
                    Text(formatDuration(duration))
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            
            if let templateName = workout.templateName {
                Text(templateName)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            HStack(spacing: 16) {
                Label("\(workout.entries?.count ?? 0) exercises", systemImage: "figure.strengthtraining.traditional")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                
                if let volume = workout.totalVolume {
                    Label(String(format: "%.1f kg", volume), systemImage: "scalemass")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                // Heart rate display
                if let heartRate = averageHeartRate {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.gradientOrangeStart)
                        Text("\(Int(heartRate)) BPM")
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            loadHeartRate()
        }
    }
    
    private func loadHeartRate() {
        Task {
            do {
                let heartRateData = try await healthKitManager.getHeartRateData(
                    from: workout.startedAt,
                    to: workout.completedAt
                )
                
                if !heartRateData.isEmpty {
                    let average = heartRateData.map { $0.1 }.reduce(0, +) / Double(heartRateData.count)
                    await MainActor.run {
                        self.averageHeartRate = average
                    }
                }
            } catch {
                // Silently fail - heart rate is optional
                print("Failed to load heart rate: \(error.localizedDescription)")
            }
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}

#Preview {
    WorkoutHistoryView()
        .modelContainer(for: [ExerciseTemplate.self, ActiveWorkout.self, WorkoutEntry.self, WorkoutSet.self, WorkoutHistory.self], inMemory: true)
}



