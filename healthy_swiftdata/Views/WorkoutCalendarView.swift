//
//  WorkoutCalendarView.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 26/12/2025.
//

import SwiftUI
import SwiftData

struct WorkoutCalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutHistory.completedAt) private var workoutHistory: [WorkoutHistory]
    @Query(sort: \BodyMeasurement.recordedAt) private var bodyMeasurements: [BodyMeasurement]
    
    @State private var currentDate = Date()
    @State private var selectedDate: Date? = nil
    @State private var showingDeleteConfirmation = false
    @State private var workoutToDelete: WorkoutHistory? = nil
    @State private var workoutToEdit: WorkoutHistory? = nil
    
    // Body measurements color (orange)
    private let bodyMeasurementColor = Color.orange
    
    // Extract unique dates from workout history (ignoring time)
    private var workoutDates: Set<DateComponents> {
        let calendar = Calendar.current
        return Set(workoutHistory.map { workout in
            calendar.dateComponents([.year, .month, .day], from: workout.completedAt)
        })
    }
    
    // Current month's date range
    private var monthDateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: currentDate)
        guard let startOfMonth = calendar.date(from: components) else {
            return (Date(), Date())
        }
        guard let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return (startOfMonth, startOfMonth)
        }
        return (startOfMonth, endOfMonth)
    }
    
    // Days in current month
    private var daysInMonth: [Date?] {
        let calendar = Calendar.current
        let (start, end) = monthDateRange
        let startComponents = calendar.dateComponents([.year, .month, .day], from: start)
        let endComponents = calendar.dateComponents([.year, .month, .day], from: end)
        
        guard let startDay = startComponents.day,
              let endDay = endComponents.day,
              let month = startComponents.month,
              let year = startComponents.year else {
            return []
        }
        
        // Get first day of week for the month
        guard let firstDate = calendar.date(from: DateComponents(year: year, month: month, day: 1)) else {
            return []
        }
        let firstWeekday = calendar.component(.weekday, from: firstDate)
        let offset = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        var days: [Date?] = []
        
        // Add empty days for offset
        for _ in 0..<offset {
            days.append(nil)
        }
        
        // Add days of the month
        for day in startDay...endDay {
            if let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentDate)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Month navigation header
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(AppTheme.accentPrimary)
                }
                
                Spacer()
                
                Text(monthYearString)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(AppTheme.accentPrimary)
                }
            }
            .padding(.horizontal)
            
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(0..<daysInMonth.count, id: \.self) { index in
                    if let date = daysInMonth[index] {
                        CalendarDayView(
                            date: date,
                            workoutTypes: getWorkoutTypes(for: date),
                            hasBodyMeasurements: hasBodyMeasurements(on: date),
                            isToday: Calendar.current.isDateInToday(date),
                            isSelected: selectedDate != nil && Calendar.current.isDate(date, inSameDayAs: selectedDate!)
                        )
                        .onTapGesture {
                            selectedDate = date
                        }
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
            .padding(.horizontal)
            
            // Show workouts and body measurements for selected date
            if let selectedDate = selectedDate {
                selectedDateContent(selectedDate)
            }
            }
            .padding(.vertical)
        }
        .background(AppTheme.background)
        .navigationDestination(item: $workoutToEdit) { workout in
            WorkoutHistoryDetailView(workout: workout)
        }
        .alert("Delete Workout", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                workoutToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let workout = workoutToDelete {
                    deleteWorkout(workout)
                }
                workoutToDelete = nil
            }
        } message: {
            if let workout = workoutToDelete {
                Text("Are you sure you want to delete the workout from \(workout.completedAt, style: .date)? This action cannot be undone.")
            }
        }
    }
    
    private func hasBodyMeasurements(on date: Date) -> Bool {
        let calendar = Calendar.current
        return bodyMeasurements.contains { measurement in
            calendar.isDate(measurement.recordedAt, inSameDayAs: date) &&
            measurement.measurementType != "weight" // Exclude body weight
        }
    }
    
    private func selectedDateContent(_ date: Date) -> some View {
        let calendar = Calendar.current
        let selectedWorkouts = workoutHistory.filter { workout in
            calendar.isDate(workout.completedAt, inSameDayAs: date)
        }
        let selectedMeasurements = bodyMeasurements.filter { measurement in
            calendar.isDate(measurement.recordedAt, inSameDayAs: date) &&
            measurement.measurementType != "weight" // Exclude body weight
        }
        
        return VStack(alignment: .leading, spacing: 16) {
            // Date header
            Text(date, style: .date)
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal)
                .padding(.top, 8)
            
            // Workouts section
            if !selectedWorkouts.isEmpty {
                Text("Workouts")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.textPrimary)
                    .padding(.horizontal)
                
                VStack(spacing: 8) {
                    ForEach(selectedWorkouts) { workout in
                        WorkoutHistoryRow(workout: workout, showDate: false)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppTheme.cardPrimary)
                            .cornerRadius(AppTheme.cornerRadiusMedium)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                workoutToEdit = workout
                            }
                            .contextMenu {
                                Button(action: {
                                    workoutToEdit = workout
                                }) {
                                    Label("Edit", systemImage: "pencil")
                                }
                                
                                Button(role: .destructive, action: {
                                    workoutToDelete = workout
                                    showingDeleteConfirmation = true
                                }) {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive, action: {
                                    workoutToDelete = workout
                                    showingDeleteConfirmation = true
                                }) {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button(action: {
                                    workoutToEdit = workout
                                }) {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(AppTheme.accentPrimary)
                            }
                    }
                }
                .padding(.horizontal)
            }
            
            // Body Measurements section
            if !selectedMeasurements.isEmpty {
                Text("Body Measurements")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.textPrimary)
                    .padding(.horizontal)
                
                VStack(spacing: 8) {
                    ForEach(selectedMeasurements) { measurement in
                        BodyMeasurementRow(measurement: measurement)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppTheme.cardPrimary)
                            .cornerRadius(AppTheme.cornerRadiusMedium)
                    }
                }
                .padding(.horizontal)
            }
            
            // Empty state
            if selectedWorkouts.isEmpty && selectedMeasurements.isEmpty {
                Text("No workouts or measurements on this day")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
    }
    
    private func deleteWorkout(_ workout: WorkoutHistory) {
        withAnimation {
            modelContext.delete(workout)
            try? modelContext.save()
        }
    }
    
    private func isWorkoutDay(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        return workoutDates.contains(dateComponents)
    }
    
    private func getWorkoutTypes(for date: Date) -> [WorkoutType] {
        let calendar = Calendar.current
        let workoutsOnDate = workoutHistory.filter { workout in
            calendar.isDate(workout.completedAt, inSameDayAs: date)
        }
        
        let types = workoutsOnDate.compactMap { workout -> WorkoutType? in
            guard let typeString = workout.workoutType else { return nil }
            return WorkoutType(rawValue: typeString)
        }
        
        // Return unique types
        return Array(Set(types))
    }
    
    private func previousMonth() {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .month, value: -1, to: currentDate) {
            currentDate = newDate
        }
    }
    
    private func nextMonth() {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .month, value: 1, to: currentDate) {
            currentDate = newDate
        }
    }
}

struct CalendarDayView: View {
    let date: Date
    let workoutTypes: [WorkoutType]
    let hasBodyMeasurements: Bool
    let isToday: Bool
    let isSelected: Bool
    
    private let bodyMeasurementColor = Color.orange
    
    private var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }
    
    private var isWorkoutDay: Bool {
        !workoutTypes.isEmpty
    }
    
    private var allSegmentColors: [Color] {
        var colors: [Color] = []
        
        // Add workout types
        let typesToShow = Array(workoutTypes.prefix(4))
        for type in typesToShow {
            colors.append(type.color)
        }
        
        // Add body measurement indicator if present
        if hasBodyMeasurements {
            colors.append(bodyMeasurementColor)
        }
        
        return colors
    }
    
    var body: some View {
        ZStack {
            // Yellow ring for selected day
            if isSelected {
                Circle()
                    .stroke(Color.yellow, lineWidth: 3)
                    .frame(width: 36, height: 36)
            }
            
            // Workout indicator - split circle for multiple types
            if isWorkoutDay {
                ZStack {
                    if workoutTypes.count == 1 && !hasBodyMeasurements {
                        // Single type - full circle
                        Circle()
                            .fill(workoutTypes[0].color)
                    } else {
                        // Multiple types or has body measurements - split circle
                        let segmentCount = allSegmentColors.count
                        ForEach(Array(allSegmentColors.enumerated()), id: \.offset) { enumIndex, color in
                            let startAngle = Double(enumIndex) / Double(segmentCount)
                            let endAngle = Double(enumIndex + 1) / Double(segmentCount)
                            
                            Circle()
                                .trim(from: startAngle, to: endAngle)
                                .fill(color)
                                .rotationEffect(.degrees(-90))
                        }
                    }
                }
                .frame(width: 36, height: 36)
            } else if hasBodyMeasurements {
                // Only body measurements, no workouts
                Circle()
                    .fill(bodyMeasurementColor)
                    .frame(width: 36, height: 36)
            } else if isToday {
                Circle()
                    .stroke(AppTheme.accentPrimary, lineWidth: 2)
                    .frame(width: 36, height: 36)
            }
            
            // Day number
            Text("\(dayNumber)")
                .font(.system(size: 16, weight: (isWorkoutDay || hasBodyMeasurements || isSelected) ? .semibold : .regular))
                .foregroundColor((isWorkoutDay || hasBodyMeasurements) ? .white : (isToday || isSelected ? AppTheme.accentPrimary : AppTheme.textPrimary))
        }
        .frame(height: 40)
    }
}

struct BodyMeasurementRow: View {
    let measurement: BodyMeasurement
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(measurement.measurementType.capitalized)
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("\(String(format: "%.1f", measurement.value)) \(measurement.unit)")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
            
            // Orange dot indicator
            Circle()
                .fill(Color.orange)
                .frame(width: 12, height: 12)
        }
    }
}

#Preview {
    WorkoutCalendarView()
        .modelContainer(for: [WorkoutHistory.self, BodyMeasurement.self], inMemory: true)
}



