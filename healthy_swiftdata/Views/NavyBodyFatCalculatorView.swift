//
//  NavyBodyFatCalculatorView.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 28/12/2025.
//

import SwiftUI
import SwiftData

struct NavyBodyFatCalculatorView: View {
    @Environment(\.modelContext) private var modelContext
    let measurements: [BodyMeasurement]
    
    @State private var gender: String = "male"
    @State private var height: String = ""
    @State private var neck: String = ""
    @State private var waist: String = ""
    @State private var hip: String = ""
    @State private var heightUnit: String = "cm"
    @State private var circumferenceUnit: String = "cm"
    @State private var calculatedBodyFat: Double?
    @State private var calculationDate: Date?
    
    private let genders = ["male", "female"]
    private let units = ["cm", "inches"]
    
    var body: some View {
        VStack(spacing: 16) {
            // Gender picker
            Picker("Gender", selection: $gender) {
                Text("Male").tag("male")
                Text("Female").tag("female")
            }
            .pickerStyle(.segmented)
            
            // Input fields
            VStack(spacing: 12) {
                measurementInputField(title: "Height", value: $height, unit: $heightUnit, measurementType: "height")
                measurementInputField(title: "Neck", value: $neck, unit: $circumferenceUnit, measurementType: "neck")
                measurementInputField(title: "Waist", value: $waist, unit: $circumferenceUnit, measurementType: "waist")
                
                if gender == "female" {
                    measurementInputField(title: "Hip", value: $hip, unit: $circumferenceUnit, measurementType: "hip")
                }
            }
            
            // Calculate button
            Button(action: calculateBodyFat) {
                Text("Calculate")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(AppTheme.background)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canCalculate ? AppTheme.accentPrimary : AppTheme.textTertiary)
                    .cornerRadius(AppTheme.cornerRadiusMedium)
            }
            .disabled(!canCalculate)
            
            // Result display
            if let bodyFat = calculatedBodyFat, let date = calculationDate {
                VStack(spacing: 8) {
                    Text(String(format: "%.1f%%", bodyFat))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.accentPrimary)
                    
                    Text("Calculated: \(date, style: .date)")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding()
                .background(AppTheme.cardTertiary)
                .cornerRadius(AppTheme.cornerRadiusMedium)
            }
        }
        .padding()
        .background(AppTheme.cardPrimary)
        .cornerRadius(AppTheme.cornerRadiusMedium)
        .onAppear {
            loadLatestMeasurements()
        }
    }
    
    private var canCalculate: Bool {
        guard let heightValue = height.toDouble(), heightValue > 0,
              let neckValue = neck.toDouble(), neckValue > 0,
              let waistValue = waist.toDouble(), waistValue > 0 else {
            return false
        }
        
        if gender == "female" {
            guard let hipValue = hip.toDouble(), hipValue > 0 else {
                return false
            }
        }
        
        return true
    }
    
    private func measurementInputField(title: String, value: Binding<String>, unit: Binding<String>, measurementType: String) -> some View {
        HStack {
            Text(title)
                .frame(width: 80, alignment: .leading)
                .foregroundColor(AppTheme.textPrimary)
            
            TextField("0.0", text: value)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .foregroundColor(AppTheme.textPrimary)
            
            Picker("Unit", selection: unit) {
                ForEach(units, id: \.self) { unitOption in
                    Text(unitOption).tag(unitOption)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 80)
        }
    }
    
    private func loadLatestMeasurements() {
        // Auto-fill from most recent measurements
        if height.isEmpty, let heightMeasurement = measurements.first(where: { $0.measurementType == "height" }) {
            height = String(format: "%.1f", heightMeasurement.value)
            heightUnit = heightMeasurement.unit
        }
        
        if neck.isEmpty, let neckMeasurement = measurements.first(where: { $0.measurementType == "neck" }) {
            neck = String(format: "%.1f", neckMeasurement.value)
            circumferenceUnit = neckMeasurement.unit
        }
        
        if waist.isEmpty, let waistMeasurement = measurements.first(where: { $0.measurementType == "waist" }) {
            waist = String(format: "%.1f", waistMeasurement.value)
            circumferenceUnit = waistMeasurement.unit
        }
        
        if gender == "female" && hip.isEmpty, let hipMeasurement = measurements.first(where: { $0.measurementType == "hip" }) {
            hip = String(format: "%.1f", hipMeasurement.value)
            circumferenceUnit = hipMeasurement.unit
        }
    }
    
    private func calculateBodyFat() {
        guard let heightValue = height.toDouble(),
              let neckValue = neck.toDouble(),
              let waistValue = waist.toDouble() else {
            return
        }
        
        let hipValue = gender == "female" ? hip.toDouble() : nil
        
        if let bodyFat = NavyBodyFatCalculator.calculateBodyFat(
            gender: gender,
            height: heightValue,
            neck: neckValue,
            waist: waistValue,
            hip: hipValue,
            heightUnit: heightUnit,
            circumferenceUnit: circumferenceUnit
        ) {
            calculatedBodyFat = bodyFat
            calculationDate = Date()
            
            // Save to measurements
            let bodyFatMeasurement = BodyMeasurement(
                measurementType: "bodyFat",
                value: bodyFat,
                unit: "%",
                recordedAt: Date(),
                notes: "Navy method - \(gender.capitalized)"
            )
            modelContext.insert(bodyFatMeasurement)
            
            do {
                try modelContext.save()
            } catch {
                print("Failed to save body fat measurement: \(error)")
            }
        }
    }
}
