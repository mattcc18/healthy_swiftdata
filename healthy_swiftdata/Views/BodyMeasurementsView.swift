//
//  BodyMeasurementsView.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 28/12/2025.
//

import SwiftUI
import SwiftData

struct BodyMeasurementsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BodyMeasurement.recordedAt, order: .reverse) private var measurements: [BodyMeasurement]
    @Query(sort: \BodyWeightEntry.recordedAt, order: .reverse) private var weightEntries: [BodyWeightEntry]
    
    @State private var showingAddMeasurementSheet = false
    @State private var showingAddWeightSheet = false
    @State private var measurementToEdit: BodyMeasurement?
    @State private var weightEntryToEdit: BodyWeightEntry?
    @State private var selectedMeasurementType: String = "neck"
    @State private var selectedMeasurementForDetail: MeasurementDetail?
    
    struct MeasurementDetail: Identifiable, Hashable {
        let id = UUID()
        let type: String
        let displayName: String
        let isWeight: Bool
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: MeasurementDetail, rhs: MeasurementDetail) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    private let measurementTypes = [
        ("weight", "Weight"),
        ("height", "Height"),
        ("neck", "Neck"),
        ("waist", "Waist"),
        ("chest", "Chest"),
        ("armLeft", "Left Arm"),
        ("armRight", "Right Arm"),
        ("legLeft", "Left Leg"),
        ("legRight", "Right Leg"),
        ("hip", "Hip")
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Body Measurements Section
                    bodyMeasurementsSection
                }
                .padding(.bottom, 20)
            }
            .background(AppTheme.background)
            .navigationTitle("Body Measurements")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingAddWeightSheet = true
                            weightEntryToEdit = nil
                        } label: {
                            Label("Add Weight", systemImage: "plus")
                        }
                        
                        Button {
                            showingAddMeasurementSheet = true
                            measurementToEdit = nil
                        } label: {
                            Label("Add Measurement", systemImage: "ruler")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddWeightSheet) {
                BodyWeightEntryForm(entry: weightEntryToEdit) { weight, unit, date, notes in
                    saveWeightEntry(weight: weight, unit: unit, recordedAt: date, notes: notes)
                }
            }
            .sheet(isPresented: $showingAddMeasurementSheet) {
                BodyMeasurementEntryForm(
                    measurement: measurementToEdit,
                    measurementType: selectedMeasurementType,
                    onSave: { measurementType, value, unit, date, notes in
                        saveMeasurement(type: measurementType, value: value, unit: unit, recordedAt: date, notes: notes)
                    }
                )
            }
            .navigationDestination(item: $selectedMeasurementForDetail) { detail in
                BodyMeasurementDetailView(
                    measurementType: detail.type,
                    displayName: detail.displayName,
                    isWeight: detail.isWeight
                )
            }
        }
    }
    
    // MARK: - Body Measurements Section
    
    private var bodyMeasurementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Measurements")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal)
            
            ForEach(measurementTypes, id: \.0) { type, displayName in
                measurementCard(type: type, displayName: displayName)
            }
        }
    }
    
    private func measurementCard(type: String, displayName: String) -> some View {
        Group {
            // Handle weight separately (uses BodyWeightEntry)
            if type == "weight" {
                weightMeasurementCard
            } else {
                // Handle other measurements (uses BodyMeasurement)
                let latestMeasurement = measurements.first { $0.measurementType == type }
                
                Button {
                    selectedMeasurementForDetail = MeasurementDetail(type: type, displayName: displayName, isWeight: false)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(AppTheme.textPrimary)
                            
                            if let measurement = latestMeasurement {
                                Text(String(format: "%.1f %@", measurement.value, measurement.unit))
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppTheme.accentPrimary)
                                
                                Text(measurement.recordedAt, style: .date)
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                            } else {
                                Text("No measurement")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Button {
                                selectedMeasurementType = type
                                measurementToEdit = nil
                                showingAddMeasurementSheet = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(AppTheme.accentPrimary)
                            }
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    .padding()
                    .background(AppTheme.cardPrimary)
                    .cornerRadius(AppTheme.cornerRadiusMedium)
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
            }
        }
    }
    
    private var weightMeasurementCard: some View {
        let latestWeight = weightEntries.first
        
        return Button {
            selectedMeasurementForDetail = MeasurementDetail(type: "weight", displayName: "Weight", isWeight: true)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weight")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    if let weight = latestWeight {
                        Text(String(format: "%.1f %@", weight.weight, weight.unit))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.accentPrimary)
                        
                        Text(weight.recordedAt, style: .date)
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    } else {
                        Text("No measurement")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button {
                        weightEntryToEdit = nil
                        showingAddWeightSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(AppTheme.accentPrimary)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .padding()
            .background(AppTheme.cardPrimary)
            .cornerRadius(AppTheme.cornerRadiusMedium)
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
    
    // MARK: - Navy Body Fat Calculator Section (Hidden - now shown in summary)
    
    // Calculator removed from body measurements page - body fat is now displayed as a metric card in the summary view
    
    // MARK: - Helper Methods
    
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
            showingAddWeightSheet = false
        } catch {
            print("Failed to save weight entry: \(error)")
        }
    }
    
    private func saveMeasurement(type: String, value: Double, unit: String, recordedAt: Date, notes: String?) {
        if let measurement = measurementToEdit {
            measurement.measurementType = type
            measurement.value = value
            measurement.unit = unit
            measurement.recordedAt = recordedAt
            measurement.notes = notes
        } else {
            let newMeasurement = BodyMeasurement(
                measurementType: type,
                value: value,
                unit: unit,
                recordedAt: recordedAt,
                notes: notes
            )
            modelContext.insert(newMeasurement)
        }
        
        do {
            try modelContext.save()
            measurementToEdit = nil
            showingAddMeasurementSheet = false
        } catch {
            print("Failed to save measurement: \(error)")
        }
    }
}

#Preview {
    BodyMeasurementsView()
        .modelContainer(for: [BodyMeasurement.self, BodyWeightEntry.self], inMemory: true)
}

