//
//  MetricHistoryView.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 27/01/2025.
//

import SwiftUI
import SwiftData

struct MetricHistoryView: View {
    let metricType: MetricType
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BodyWeightEntry.recordedAt, order: .reverse) private var weightEntries: [BodyWeightEntry]
    @Query private var workoutHistory: [WorkoutHistory]
    
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var showingAddEntry = false
    @State private var entryToEdit: BodyWeightEntry?
    
    var body: some View {
        List {
            // Add new entry button
            Section {
                Button(action: {
                    entryToEdit = nil
                    showingAddEntry = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(AppTheme.accentPrimary)
                        Text("Add New Entry")
                            .foregroundColor(AppTheme.accentPrimary)
                    }
                }
            }
            .listRowBackground(AppTheme.cardPrimary)
            
            // History entries
            if metricType == .bodyWeight {
                if weightEntries.isEmpty {
                    Section {
                        Text("No history available")
                            .foregroundColor(AppTheme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                    .listRowBackground(AppTheme.cardPrimary)
                } else {
                    Section(header: Text("History")) {
                        ForEach(weightEntries) { entry in
                            HistoryRowView(entry: entry, metricType: metricType)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button {
                                        entryToEdit = entry
                                        showingAddEntry = true
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(AppTheme.accentPrimary)
                                    
                                    Button(role: .destructive) {
                                        deleteEntry(entry)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listRowBackground(AppTheme.cardPrimary)
                }
            } else {
                if workoutHistory.isEmpty {
                    Section {
                        Text("No history available")
                            .foregroundColor(AppTheme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                    .listRowBackground(AppTheme.cardPrimary)
                } else {
                    Section(header: Text("History")) {
                        ForEach(workoutHistory) { workout in
                            HistoryRowView(entry: workout, metricType: metricType)
                        }
                    }
                    .listRowBackground(AppTheme.cardPrimary)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .listRowBackground(AppTheme.cardPrimary)
        .navigationTitle("\(metricType.displayName) History")
        .sheet(isPresented: $showingAddEntry) {
            if metricType == .bodyWeight {
                BodyWeightEntryForm(entry: entryToEdit) { weight, unit, date, notes in
                    saveEntry(weight: weight, unit: unit, recordedAt: date, notes: notes)
                }
            }
        }
    }
    
    
    private func saveEntry(weight: Double, unit: String, recordedAt: Date, notes: String?) {
        if let entry = entryToEdit {
            // Update existing entry
            entry.weight = weight
            entry.unit = unit
            entry.recordedAt = recordedAt
            entry.notes = notes
            try? modelContext.save()
            
            // Save to HealthKit
            Task {
                do {
                    try await healthKitManager.saveBodyWeight(weight: weight, unit: unit, date: recordedAt)
                } catch {
                    print("Failed to save body weight to HealthKit: \(error.localizedDescription)")
                }
            }
        } else {
            // Create new entry
            let newEntry = BodyWeightEntry(
                weight: weight,
                unit: unit,
                recordedAt: recordedAt,
                notes: notes
            )
            modelContext.insert(newEntry)
            try? modelContext.save()
            
            // Save to HealthKit
            Task {
                do {
                    try await healthKitManager.saveBodyWeight(weight: weight, unit: unit, date: recordedAt)
                } catch {
                    print("Failed to save body weight to HealthKit: \(error.localizedDescription)")
                }
            }
        }
        entryToEdit = nil
    }
    
    private func deleteEntry(_ entry: BodyWeightEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
    }
}

struct HistoryRowView: View {
    let entry: Any
    let metricType: MetricType
    
    var body: some View {
        if metricType == .bodyWeight, let weightEntry = entry as? BodyWeightEntry {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(String(format: "%.1f", weightEntry.weight)) \(weightEntry.unit)")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    Text(weightEntry.recordedAt, style: .date)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                HStack {
                    Text(weightEntry.recordedAt, style: .time)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    if let notes = weightEntry.notes, !notes.isEmpty {
                        Text("•")
                            .foregroundColor(AppTheme.textSecondary)
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.vertical, 4)
        } else if let workout = entry as? WorkoutHistory {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(workout.completedAt, style: .date)
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    if let duration = workout.durationSeconds {
                        Text(formatDuration(duration))
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                
                if let templateName = workout.templateName {
                    Text(templateName)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .padding(.vertical, 4)
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
    NavigationView {
        MetricHistoryView(metricType: .bodyWeight)
    }
    .modelContainer(for: [BodyWeightEntry.self], inMemory: true)
}

