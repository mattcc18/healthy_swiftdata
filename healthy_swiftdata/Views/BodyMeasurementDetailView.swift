//
//  BodyMeasurementDetailView.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 28/12/2025.
//

import SwiftUI
import SwiftData
import Charts

struct BodyMeasurementDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let measurementType: String
    let displayName: String
    let isWeight: Bool
    
    @Query(sort: \BodyMeasurement.recordedAt, order: .reverse) private var allMeasurements: [BodyMeasurement]
    @Query(sort: \BodyWeightEntry.recordedAt, order: .reverse) private var allWeightEntries: [BodyWeightEntry]
    
    @State private var selectedDate: Date? = nil
    @State private var showingAddSheet = false
    @State private var entryToEdit: BodyMeasurement?
    @State private var weightEntryToEdit: BodyWeightEntry?
    
    private var chartData: [ChartDataPoint] {
        if isWeight {
            return allWeightEntries.map { entry in
                ChartDataPoint(date: entry.recordedAt, value: entry.weight)
            }.sorted { $0.date < $1.date }
        } else {
            return allMeasurements
                .filter { $0.measurementType == measurementType }
                .map { measurement in
                    ChartDataPoint(date: measurement.recordedAt, value: measurement.value)
                }
                .sorted { $0.date < $1.date }
        }
    }
    
    private var entries: [MeasurementEntry] {
        if isWeight {
            return allWeightEntries.map { entry in
                MeasurementEntry(
                    id: entry.id.uuidString,
                    date: entry.recordedAt,
                    value: entry.weight,
                    unit: entry.unit,
                    notes: entry.notes
                )
            }
        } else {
            return allMeasurements
                .filter { $0.measurementType == measurementType }
                .map { measurement in
                    MeasurementEntry(
                        id: measurement.id.uuidString,
                        date: measurement.recordedAt,
                        value: measurement.value,
                        unit: measurement.unit,
                        notes: measurement.notes
                    )
                }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Chart
                    if !chartData.isEmpty {
                        chartSection
                    } else {
                        emptyChartSection
                    }
                    
                    // Historical entries
                    historicalEntriesSection
                }
                .padding(.bottom, 20)
            }
            .background(AppTheme.background)
            .navigationTitle(displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if isWeight {
                            weightEntryToEdit = nil
                        } else {
                            entryToEdit = nil
                        }
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                if isWeight {
                    BodyWeightEntryForm(entry: weightEntryToEdit) { weight, unit, date, notes in
                        saveWeightEntry(weight: weight, unit: unit, recordedAt: date, notes: notes)
                    }
                } else {
                    BodyMeasurementEntryForm(
                        measurement: entryToEdit,
                        measurementType: measurementType,
                        onSave: { _, value, unit, date, notes in
                            saveMeasurement(value: value, unit: unit, recordedAt: date, notes: notes)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Chart Section
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Chart {
                ForEach(chartData) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(AppTheme.primaryGradient)
                    
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(AppTheme.accentPrimary)
                    .symbolSize(60)
                }
                
                // Cursor line
                if let selectedDate = selectedDate {
                    RuleMark(x: .value("Selected Date", selectedDate))
                        .foregroundStyle(AppTheme.accentPrimary.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                    
                    // Highlight selected point
                    if let selectedPoint = findClosestPoint(to: selectedDate) {
                        PointMark(
                            x: .value("Date", selectedPoint.date),
                            y: .value("Value", selectedPoint.value)
                        )
                        .foregroundStyle(AppTheme.accentPrimary)
                        .symbolSize(100)
                    }
                }
            }
            .chartXSelection(value: $selectedDate)
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine()
                        .foregroundStyle(AppTheme.borderSubtle)
                    AxisValueLabel(format: .dateTime.month().day())
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine()
                        .foregroundStyle(AppTheme.borderSubtle)
                    AxisValueLabel()
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .chartBackground { _ in
                AppTheme.background
            }
            .frame(height: 300)
            .padding(.horizontal)
            
            // Display selected value above chart
            if let selectedDate = selectedDate,
               let selectedPoint = findClosestPoint(to: selectedDate) {
                VStack(spacing: 8) {
                    Text(String(format: "%.1f %@", selectedPoint.value, entries.first?.unit ?? ""))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.accentPrimary)
                    
                    Text(selectedPoint.date, style: .date)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding()
                .background(AppTheme.cardPrimary)
                .cornerRadius(AppTheme.cornerRadiusMedium)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
    }
    
    private var emptyChartSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.largeTitle)
                .foregroundColor(AppTheme.textSecondary.opacity(0.5))
            Text("No data yet")
                .font(.headline)
                .foregroundColor(AppTheme.textSecondary)
            Text("Add your first entry to see the chart")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    // MARK: - Historical Entries Section
    
    private var historicalEntriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("History")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal)
            
            if entries.isEmpty {
                VStack(spacing: 8) {
                    Text("No entries yet")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.cardPrimary)
                .cornerRadius(AppTheme.cornerRadiusMedium)
                .padding(.horizontal)
            } else {
                ForEach(entries) { entry in
                    MeasurementHistoryRow(
                        entry: entry,
                        onEdit: {
                            if isWeight {
                                weightEntryToEdit = allWeightEntries.first { $0.id.uuidString == entry.id }
                            } else {
                                entryToEdit = allMeasurements.first { $0.id.uuidString == entry.id }
                            }
                            showingAddSheet = true
                        },
                        onDelete: {
                            if isWeight {
                                if let weightEntry = allWeightEntries.first(where: { $0.id.uuidString == entry.id }) {
                                    modelContext.delete(weightEntry)
                                    try? modelContext.save()
                                }
                            } else {
                                if let measurement = allMeasurements.first(where: { $0.id.uuidString == entry.id }) {
                                    modelContext.delete(measurement)
                                    try? modelContext.save()
                                }
                            }
                        }
                    )
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func findClosestPoint(to date: Date) -> ChartDataPoint? {
        guard !chartData.isEmpty else { return nil }
        return chartData.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
    }
    
    private func saveWeightEntry(weight: Double, unit: String, recordedAt: Date, notes: String?) {
        if let entry = weightEntryToEdit {
            entry.weight = weight
            entry.unit = unit
            entry.recordedAt = recordedAt
            entry.notes = notes
        } else {
            let newEntry = BodyWeightEntry(
                weight: weight,
                unit: unit,
                recordedAt: recordedAt,
                notes: notes
            )
            modelContext.insert(newEntry)
        }
        
        do {
            try modelContext.save()
            weightEntryToEdit = nil
            showingAddSheet = false
        } catch {
            print("Failed to save weight entry: \(error)")
        }
    }
    
    private func saveMeasurement(value: Double, unit: String, recordedAt: Date, notes: String?) {
        if let measurement = entryToEdit {
            measurement.value = value
            measurement.unit = unit
            measurement.recordedAt = recordedAt
            measurement.notes = notes
        } else {
            let newMeasurement = BodyMeasurement(
                measurementType: measurementType,
                value: value,
                unit: unit,
                recordedAt: recordedAt,
                notes: notes
            )
            modelContext.insert(newMeasurement)
        }
        
        do {
            try modelContext.save()
            entryToEdit = nil
            showingAddSheet = false
        } catch {
            print("Failed to save measurement: \(error)")
        }
    }
}

// MARK: - Supporting Types

struct MeasurementEntry: Identifiable {
    let id: String
    let date: Date
    let value: Double
    let unit: String
    let notes: String?
}

struct MeasurementHistoryRow: View {
    let entry: MeasurementEntry
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: "%.1f %@", entry.value, entry.unit))
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                
                if let notes = entry.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Button {
                    onEdit()
                } label: {
                    Image(systemName: "pencil")
                        .foregroundColor(AppTheme.accentPrimary)
                }
                
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(AppTheme.cardPrimary)
        .cornerRadius(AppTheme.cornerRadiusMedium)
    }
}

#Preview {
    BodyMeasurementDetailView(
        measurementType: "height",
        displayName: "Height",
        isWeight: false
    )
    .modelContainer(for: [BodyMeasurement.self, BodyWeightEntry.self], inMemory: true)
}


