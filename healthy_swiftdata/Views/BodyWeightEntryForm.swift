//
//  BodyWeightEntryForm.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 25/12/2025.
//

import SwiftUI

struct BodyWeightEntryForm: View {
    @Environment(\.dismiss) private var dismiss
    let entry: BodyWeightEntry?
    let onSave: (Double, String, Date, String?) -> Void
    
    @State private var weight: String
    @State private var unit: String
    @State private var recordedAt: Date
    @State private var notes: String
    
    private let units = ["kg", "lbs"]
    
    init(entry: BodyWeightEntry? = nil, onSave: @escaping (Double, String, Date, String?) -> Void) {
        self.entry = entry
        self.onSave = onSave
        
        if let entry = entry {
            _weight = State(initialValue: String(format: "%.1f", entry.weight))
            _unit = State(initialValue: entry.unit)
            _recordedAt = State(initialValue: entry.recordedAt)
            _notes = State(initialValue: entry.notes ?? "")
        } else {
            _weight = State(initialValue: "")
            _unit = State(initialValue: "kg")
            _recordedAt = State(initialValue: Date())
            _notes = State(initialValue: "")
        }
    }
    
    private var isValid: Bool {
        if let weightValue = weight.toDouble(), weightValue > 0 {
            return true
        }
        return false
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Weight") {
                    HStack {
                        TextField("Weight", text: $weight)
                            .keyboardType(.decimalPad)
                        
                        Picker("Unit", selection: $unit) {
                            ForEach(units, id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 80)
                    }
                    
                    DatePicker("Date", selection: $recordedAt, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section("Notes") {
                    TextField("Notes (Optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(entry == nil ? "Add Weight" : "Edit Weight")
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
        guard let weightValue = weight.toDouble(), weightValue > 0 else {
            return
        }
        
        let notesText = notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces)
        onSave(weightValue, unit, recordedAt, notesText)
        dismiss()
    }
}

#Preview {
    BodyWeightEntryForm { weight, unit, date, notes in
        print("Save: \(weight) \(unit) at \(date)")
    }
}

