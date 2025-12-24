//
//  WorkoutHistoryView.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 27/01/2025.
//

import SwiftUI
import SwiftData

struct WorkoutHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        sort: \WorkoutHistory.completedAt,
        order: .reverse
    ) private var allWorkouts: [WorkoutHistory]
    
    @State private var displayedWorkouts: [WorkoutHistory] = []
    @State private var currentLimit = 25
    private let pageSize = 25
    
    var body: some View {
        NavigationView {
            Group {
                if displayedWorkouts.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(displayedWorkouts) { workout in
                            NavigationLink(destination: WorkoutHistoryDetailView(workout: workout)) {
                                WorkoutHistoryRow(workout: workout)
                            }
                        }
                        .onDelete(perform: deleteWorkouts)
                        
                        // Load more button
                        if displayedWorkouts.count < allWorkouts.count {
                            Button(action: loadMore) {
                                HStack {
                                    Spacer()
                                    Text("Load More")
                                        .foregroundColor(.blue)
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Workout History")
            .onAppear {
                loadInitialWorkouts()
            }
            .onChange(of: allWorkouts) { _, _ in
                loadInitialWorkouts()
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No Workout History")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Complete workouts to see them here")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func loadInitialWorkouts() {
        // Take first pageSize workouts from the sorted query results
        displayedWorkouts = Array(allWorkouts.prefix(pageSize))
        currentLimit = pageSize
    }
    
    private func loadMore() {
        let nextLimit = min(currentLimit + pageSize, allWorkouts.count)
        displayedWorkouts = Array(allWorkouts.prefix(nextLimit))
        currentLimit = nextLimit
    }
    
    private func deleteWorkouts(at offsets: IndexSet) {
        for index in offsets {
            let workout = displayedWorkouts[index]
            modelContext.delete(workout)
        }
        try? modelContext.save()
    }
}

struct WorkoutHistoryRow: View {
    let workout: WorkoutHistory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(workout.completedAt, style: .date)
                    .font(.headline)
                Spacer()
                if let duration = workout.durationSeconds {
                    Text(formatDuration(duration))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            if let templateName = workout.templateName {
                Text(templateName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 16) {
                Label("\(workout.entries?.count ?? 0) exercises", systemImage: "figure.strengthtraining.traditional")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let volume = workout.totalVolume {
                    Label(String(format: "%.1f kg", volume), systemImage: "scalemass")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
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

