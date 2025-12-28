//
//  CategoryFilterButton.swift
//  healthy_swiftdata
//
//  Extracted from ExercisesView.swift for shared use across views
//

import SwiftUI

struct CategoryFilterButton: View {
    let title: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void
    
    init(title: String, icon: String? = nil, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(isSelected ? AppTheme.background : AppTheme.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? AppTheme.accentPrimary : AppTheme.cardTertiary)
            .cornerRadius(AppTheme.cornerRadiusMedium)
        }
    }
}

