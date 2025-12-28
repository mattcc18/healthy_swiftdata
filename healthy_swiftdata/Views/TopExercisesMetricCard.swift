//
//  TopExercisesMetricCard.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 27/01/2025.
//

import SwiftUI

struct TopExercisesMetricCard: View {
    let topExercises: [TopExercise]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Top Exercises")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
            }
            
            // Exercises list
            if topExercises.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "star")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.textSecondary.opacity(0.5))
                    Text("Mark exercises as favorites to see them here")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(topExercises) { exercise in
                        HStack(spacing: 12) {
                            // Rank indicator
                            ZStack {
                                Circle()
                                    .fill(AppTheme.accentPrimary.opacity(0.2))
                                    .frame(width: 32, height: 32)
                                
                                Text("\(exercise.rank)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(AppTheme.accentPrimary)
                            }
                            
                            // Exercise name
                            Text(exercise.name)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(AppTheme.textPrimary)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            // 1RM value
                            Text(String(format: "%.1f kg", exercise.estimated1RM))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppTheme.accentPrimary)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(AppTheme.cardTertiary)
                        .cornerRadius(AppTheme.cornerRadiusSmall)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(AppTheme.cardPrimary)
        .cornerRadius(AppTheme.cornerRadiusLarge)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge)
                .stroke(AppTheme.borderSubtle, lineWidth: 0.5)
        )
        .shadow(color: AppTheme.accentPrimary.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private func rankColor(for rank: Int) -> Color {
        switch rank {
        case 1:
            return AppTheme.gradientOrangeStart // Gold
        case 2:
            return AppTheme.textSecondary // Silver
        case 3:
            return AppTheme.gradientCyan // Bronze
        default:
            return AppTheme.accentPrimary
        }
    }
}

#Preview {
    TopExercisesMetricCard(
        topExercises: [
            TopExercise(name: "Bench Press", estimated1RM: 120.5, rank: 1),
            TopExercise(name: "Squat", estimated1RM: 180.0, rank: 2),
            TopExercise(name: "Deadlift", estimated1RM: 200.0, rank: 3)
        ]
    )
    .padding()
    .background(AppTheme.background)
}

