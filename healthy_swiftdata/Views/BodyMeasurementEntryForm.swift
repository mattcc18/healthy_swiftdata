//
//  BodyMeasurementEntryForm.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 28/12/2025.
//

import SwiftUI

struct BodyMeasurementEntryForm: View {
    @Environment(\.dismiss) private var dismiss
    let measurement: BodyMeasurement?
    let measurementType: String
    let onSave: (String, Double, String, Date, String?) -> Void
    
    @State private var value: String
    @State private var unit: String
    @State private var recordedAt: Date
    @State private var notes: String
    
    private let units = ["cm", "inches"]
    
    private let measurementTypeNames: [String: String] = [
        "neck": "Neck",
        "height": "Height",
        "waist": "Waist",
        "chest": "Chest",
        "armLeft": "Left Arm",
        "armRight": "Right Arm",
        "legLeft": "Left Leg",
        "legRight": "Right Leg",
        "hip": "Hip"
    ]
    
    init(measurement: BodyMeasurement? = nil, measurementType: String, onSave: @escaping (String, Double, String, Date, String?) -> Void) {
        self.measurement = measurement
        self.measurementType = measurementType
        self.onSave = onSave
        
        if let measurement = measurement {
            _value = State(initialValue: String(format: "%.1f", measurement.value))
            _unit = State(initialValue: measurement.unit)
            _recordedAt = State(initialValue: measurement.recordedAt)
            _notes = State(initialValue: measurement.notes ?? "")
        } else {
            _value = State(initialValue: "")
            _unit = State(initialValue: "cm")
            _recordedAt = State(initialValue: Date())
            _notes = State(initialValue: "")
        }
    }
    
    private var isValid: Bool {
        if let valueDouble = value.toDouble(), valueDouble > 0 {
            return true
        }
        return false
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Text(measurementTypeNames[measurementType] ?? measurementType.capitalized)
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                }
                .listRowBackground(AppTheme.cardPrimary)
                
                Section("Measurement") {
                    HStack {
                        TextField("Value", text: $value)
                            .keyboardType(.decimalPad)
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Picker("Unit", selection: $unit) {
                            ForEach(units, id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 100)
                    }
                    
                    DatePicker("Date", selection: $recordedAt, displayedComponents: [.date, .hourAndMinute])
                }
                .listRowBackground(AppTheme.cardPrimary)
                
                Section("Notes") {
                    TextField("Notes (Optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .foregroundColor(AppTheme.textPrimary)
                }
                .listRowBackground(AppTheme.cardPrimary)
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .navigationTitle(measurement == nil ? "Add Measurement" : "Edit Measurement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEntry()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private func saveEntry() {
        guard let valueDouble = value.toDouble(), valueDouble > 0 else { return }
        
        onSave(measurementType, valueDouble, unit, recordedAt, notes.isEmpty ? nil : notes)
        dismiss()
    }
}


