//
//  NumberFormatter.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 25/12/2025.
//

import Foundation

extension String {
    /// Converts a string to a Double, handling both comma and period as decimal separators
    /// This ensures locale-independent parsing for decimal numbers
    func toDouble() -> Double? {
        // Replace comma with period for consistent parsing
        let normalized = self.replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }
}

