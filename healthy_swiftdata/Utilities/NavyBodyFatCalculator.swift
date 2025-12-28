//
//  NavyBodyFatCalculator.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 28/12/2025.
//

import Foundation

struct NavyBodyFatCalculator {
    /// Calculate body fat percentage using US Navy formula
    /// - Parameters:
    ///   - gender: "male" or "female"
    ///   - height: Height in cm or inches (will be converted to cm if needed)
    ///   - neck: Neck circumference in cm or inches
    ///   - waist: Waist circumference in cm or inches
    ///   - hip: Hip circumference in cm or inches (required for females, optional for males)
    ///   - heightUnit: Unit for height ("cm" or "inches")
    ///   - circumferenceUnit: Unit for circumferences ("cm" or "inches")
    /// - Returns: Body fat percentage, or nil if inputs are invalid
    static func calculateBodyFat(
        gender: String,
        height: Double,
        neck: Double,
        waist: Double,
        hip: Double? = nil,
        heightUnit: String = "cm",
        circumferenceUnit: String = "cm"
    ) -> Double? {
        // Convert all measurements to cm for calculation
        let heightCm = heightUnit == "inches" ? height * 2.54 : height
        let neckCm = circumferenceUnit == "inches" ? neck * 2.54 : neck
        let waistCm = circumferenceUnit == "inches" ? waist * 2.54 : waist
        let hipCm = hip != nil ? (circumferenceUnit == "inches" ? hip! * 2.54 : hip!) : nil
        
        // Validate inputs
        guard heightCm > 0, neckCm > 0, waistCm > 0 else { return nil }
        guard heightCm > neckCm, waistCm > neckCm else { return nil }
        
        let genderLower = gender.lowercased()
        
        if genderLower == "male" {
            // Male formula: BF% = 495 / (1.0324 - 0.19077 * log10(waist - neck) + 0.15456 * log10(height)) - 450
            let waistNeckDiff = waistCm - neckCm
            guard waistNeckDiff > 0 else { return nil }
            
            let logWaistNeck = log10(waistNeckDiff)
            let logHeight = log10(heightCm)
            
            let denominator = 1.0324 - 0.19077 * logWaistNeck + 0.15456 * logHeight
            guard denominator > 0 else { return nil }
            
            let bodyFat = 495.0 / denominator - 450.0
            return max(0, min(100, bodyFat)) // Clamp between 0 and 100
        } else if genderLower == "female" {
            // Female formula: BF% = 495 / (1.29579 - 0.35004 * log10(waist + hip - neck) + 0.22100 * log10(height)) - 450
            guard let hipCm = hipCm, hipCm > 0 else { return nil }
            
            let waistHipNeck = waistCm + hipCm - neckCm
            guard waistHipNeck > 0 else { return nil }
            
            let logWaistHipNeck = log10(waistHipNeck)
            let logHeight = log10(heightCm)
            
            let denominator = 1.29579 - 0.35004 * logWaistHipNeck + 0.22100 * logHeight
            guard denominator > 0 else { return nil }
            
            let bodyFat = 495.0 / denominator - 450.0
            return max(0, min(100, bodyFat)) // Clamp between 0 and 100
        }
        
        return nil
    }
}


