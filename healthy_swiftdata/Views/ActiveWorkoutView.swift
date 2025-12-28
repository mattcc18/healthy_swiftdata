//
//  ActiveWorkoutView.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 27/01/2025.
//

import SwiftUI
import SwiftData
import HealthKit

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Query private var activeWorkouts: [ActiveWorkout]
    @Query private var exerciseTemplates: [ExerciseTemplate]
    @Query(sort: [
        SortDescriptor(\WorkoutTemplate.lastUsed, order: .reverse),
        SortDescriptor(\WorkoutTemplate.createdAt, order: .reverse)
    ]) private var workoutTemplates: [WorkoutTemplate]
    @State private var showingAddExercise = false
    @State private var showingFinishConfirmation = false
    @State private var showingCreateTemplate = false
    @State private var selectedTemplateForEdit: WorkoutTemplate?
    @State private var showingDeleteConfirmation = false
    @State private var templateToDelete: WorkoutTemplate?
    @State private var showingDiscardConfirmation = false
    @State private var templateToStart: WorkoutTemplate?
    @StateObject private var restTimerManager = RestTimerManager()
    @State private var workoutElapsedTime: TimeInterval = 0
    @State private var workoutTimer: Timer?
    @State private var currentExerciseIndex: Int = 0
    @State private var selectedExerciseIndex: Int = 0
    
    // MARK: - Helper Functions
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private var activeWorkout: ActiveWorkout? {
        activeWorkouts.first
    }
    
    var body: some View {
        NavigationView {
            Group {
                if let workout = activeWorkout {
                    workoutContent(workout: workout)
                } else {
                    templatesView
                }
            }
            .navigationTitle(activeWorkout != nil ? "" : "Start a Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if activeWorkout != nil {
                        Button("Finish") {
                            showingFinishConfirmation = true
                        }
                        .foregroundColor(AppTheme.gradientOrangeStart)
                    } else {
                        Button(action: {
                            showingCreateTemplate = true
                        }) {
                            Image(systemName: "plus")
                        }
                        .foregroundColor(AppTheme.accentPrimary)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if activeWorkout != nil {
                        Button("Add Exercise") {
                            showingAddExercise = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddExercise) {
                AddExerciseSheet(
                    exerciseTemplates: exerciseTemplates,
                    onAddExercises: { exerciseNames in
                        if let workout = activeWorkout {
                            for exerciseName in exerciseNames {
                                addExercise(name: exerciseName, to: workout)
                            }
                        }
                    }
                )
            }
            .alert("Finish Workout", isPresented: $showingFinishConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Finish", role: .destructive) {
                    if let workout = activeWorkout {
                        finishWorkout(workout)
                    }
                }
            } message: {
                Text("Are you sure you want to finish this workout?")
            }
            .onAppear {
                // Restore timer state when view appears
                restTimerManager.restoreTimerIfNeeded()
                // Start workout stopwatch if active workout exists
                if activeWorkout != nil {
                    startWorkoutStopwatch()
                }
            }
            .onDisappear {
                // Don't stop stopwatch when view disappears - keep it running
                // The stopwatch should continue even if user navigates away temporarily
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                // Restore timer when app comes to foreground
                if oldPhase == .background && newPhase == .active {
                    restTimerManager.restoreTimerIfNeeded()
                    if activeWorkout != nil {
                        // Recalculate elapsed time based on start time (not timer)
                        updateWorkoutElapsedTime()
                        startWorkoutStopwatch()
                    }
                }
                // Don't stop stopwatch when backgrounding - it will recalculate on foreground
            }
            .onChange(of: activeWorkouts) { _, _ in
                if activeWorkout != nil {
                    startWorkoutStopwatch()
                } else {
                    stopWorkoutStopwatch()
                }
            }
        }
    }
    
    @ViewBuilder
    private func workoutContent(workout: ActiveWorkout) -> some View {
        List {
            timerCardSection
            
            // Main exercises section with swipe navigation
            if let entries = workout.entries, !entries.isEmpty {
                mainExercisesSection(entries: entries, workout: workout)
            } else {
                Section {
                    Text("No exercises added yet")
                        .foregroundColor(AppTheme.textSecondary)
                }
                .listRowBackground(AppTheme.cardPrimary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .listRowBackground(AppTheme.cardPrimary)
    }
    
    private var timerCardSection: some View {
        Section {
            VStack(spacing: 12) {
                if restTimerManager.isActive {
                    restTimerCard
                } else {
                    durationTimerCard
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .listRowBackground(AppTheme.cardPrimary)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
    
    private var restTimerCard: some View {
        VStack(spacing: 8) {
            // Large rest timer
            Text(formatRestTime(restTimerManager.timeRemaining))
                .font(.system(size: 56, weight: .bold, design: .monospaced))
                .foregroundColor(AppTheme.accentPrimary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            
            // Horizontal progress bar
            if restTimerManager.initialDuration > 0 {
                restTimerProgressBar
            }
            
            Text("Rest: \(restTimerManager.exerciseName) - Set \(restTimerManager.setNumber)")
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
            
            // Small duration timer
            Text(formatElapsedTime(workoutElapsedTime))
                .font(.system(size: 24, weight: .semibold, design: .monospaced))
                .foregroundColor(AppTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            
            // Rest timer controls
            restTimerControls
        }
    }
    
    private var restTimerProgressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Rectangle()
                    .fill(AppTheme.borderSubtle)
                    .frame(height: 4)
                    .cornerRadius(2)
                
                // Progress fill
                let progress = Double(restTimerManager.timeRemaining) / Double(restTimerManager.initialDuration)
                Rectangle()
                    .fill(AppTheme.accentPrimary)
                    .frame(width: geometry.size.width * progress, height: 4)
                    .cornerRadius(2)
                    .animation(.linear(duration: 1.0), value: restTimerManager.timeRemaining)
            }
        }
        .frame(height: 4)
        .padding(.horizontal)
    }
    
    private var restTimerControls: some View {
        HStack(spacing: 12) {
            // -15 seconds button
            Button {
                restTimerManager.adjustTime(by: -15)
            } label: {
                Text("-15")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.textPrimary)
                    .frame(width: 50, height: 36)
                    .background(AppTheme.cardTertiary)
                    .cornerRadius(AppTheme.cornerRadiusSmall)
            }
            .buttonStyle(.plain)
            
            // Skip rest button
            Button {
                restTimerManager.stopTimer()
            } label: {
                Text("Skip Rest")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(AppTheme.cardTertiary)
                    .cornerRadius(AppTheme.cornerRadiusSmall)
            }
            .buttonStyle(.plain)
            
            // +15 seconds button
            Button {
                restTimerManager.adjustTime(by: 15)
            } label: {
                Text("+15")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.textPrimary)
                    .frame(width: 50, height: 36)
                    .background(AppTheme.cardTertiary)
                    .cornerRadius(AppTheme.cornerRadiusSmall)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
        .allowsHitTesting(true)
    }
    
    private var durationTimerCard: some View {
        Text(formatElapsedTime(workoutElapsedTime))
            .font(.system(size: 56, weight: .bold, design: .monospaced))
            .foregroundColor(AppTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.8)
            .lineLimit(1)
    }
    
    @ViewBuilder
    private func mainExercisesSection(entries: [WorkoutEntry], workout: ActiveWorkout) -> some View {
        let mainEntries = entries.filter { $0.isWarmup != true }.sorted(by: { $0.order < $1.order })
        if !mainEntries.isEmpty {
            Section {
                VStack(spacing: 0) {
                    // Custom page indicator above exercise title
                    pageIndicator(count: mainEntries.count)
                    
                    // Use ScrollView instead of TabView for better spacing control
                    GeometryReader { geometry in
                        ScrollViewReader { proxy in
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 0) {
                                    ForEach(Array(mainEntries.enumerated()), id: \.element.id) { index, entry in
                                        ExerciseView(
                                            entry: entry,
                                            workout: workout,
                                            modelContext: modelContext,
                                            restTimerManager: restTimerManager,
                                            onAddSet: { entry in
                                                addSet(to: entry)
                                            },
                                            onDeleteHighestSet: { entry in
                                                deleteHighestSet(from: entry)
                                            },
                                            onDeleteSet: { set in
                                                deleteSet(set)
                                            },
                                            onSetComplete: { rest, name, num in
                                                restTimerManager.startTimer(
                                                    seconds: rest ?? 0,
                                                    exerciseName: name,
                                                    setNumber: num
                                                )
                                            }
                                        )
                                        .frame(width: geometry.size.width)
                                        .frame(maxHeight: .infinity, alignment: .top)
                                        .id(index)
                                    }
                                }
                            }
                            .scrollTargetBehavior(.paging)
                            .contentMargins(.zero, for: .scrollContent)
                            .onAppear {
                                // Scroll to selected exercise on appear
                                if selectedExerciseIndex < mainEntries.count {
                                    proxy.scrollTo(selectedExerciseIndex, anchor: .leading)
                                }
                            }
                            .onChange(of: selectedExerciseIndex) { oldValue, newValue in
                                // Scroll when selection changes programmatically
                                withAnimation {
                                    proxy.scrollTo(newValue, anchor: .leading)
                                }
                            }
                        }
                    }
                    .frame(height: calculateExerciseViewHeight(for: mainEntries[selectedExerciseIndex]))
                }
                .background(AppTheme.background)
            }
            .listRowBackground(AppTheme.background)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
    }
    
    private func pageIndicator(count: Int) -> some View {
        HStack {
            Spacer()
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill(index == selectedExerciseIndex ? AppTheme.accentPrimary : AppTheme.textTertiary)
                    .frame(width: 6, height: 6)
                if index < count - 1 {
                    Spacer()
                        .frame(width: 4)
                }
            }
            Spacer()
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
    
    private var templatesView: some View {
        Group {
            if workoutTemplates.isEmpty {
                emptyTemplatesState
            } else {
                templateList
            }
        }
        .sheet(isPresented: $showingCreateTemplate) {
            WorkoutTemplateEditView(template: nil)
        }
        .sheet(item: $selectedTemplateForEdit) { template in
            WorkoutTemplateEditView(template: template)
        }
        .alert("Discard Existing Workout?", isPresented: $showingDiscardConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Discard", role: .destructive) {
                if let template = templateToStart {
                    discardAndStartWorkout(from: template)
                }
            }
        } message: {
            Text("Starting a new workout will discard your current active workout. This cannot be undone.")
        }
        .alert("Delete Template", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let template = templateToDelete {
                    deleteTemplate(template)
                }
            }
        } message: {
            Text("Are you sure you want to delete this template? Active workouts started from this template will not be affected.")
        }
    }
    
    private var emptyTemplatesState: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.textSecondary)
            Text("No Templates")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.textPrimary)
            Text("Create a workout template to get started")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
            Button("Create Template") {
                showingCreateTemplate = true
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accentPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background)
    }
    
    private var templateList: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(workoutTemplates) { template in
                    WorkoutTemplateRow(
                        template: template,
                        onTap: {
                            startWorkout(from: template)
                        },
                        onEdit: {
                            selectedTemplateForEdit = template
                        },
                        onDelete: {
                            templateToDelete = template
                            showingDeleteConfirmation = true
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(AppTheme.background)
    }
    
    private func deleteTemplate(_ template: WorkoutTemplate) {
        modelContext.delete(template)
        try? modelContext.save()
    }
    
    private func startWorkout(from template: WorkoutTemplate) {
        if activeWorkout != nil {
            templateToStart = template
            showingDiscardConfirmation = true
        } else {
            createWorkoutFromTemplate(template)
        }
    }
    
    private func discardAndStartWorkout(from template: WorkoutTemplate) {
        if let workout = activeWorkout {
            modelContext.delete(workout)
            try? modelContext.save()
        }
        createWorkoutFromTemplate(template)
    }
    
    private func createWorkoutFromTemplate(_ template: WorkoutTemplate) {
        let newWorkout = ActiveWorkout(
            startedAt: Date(),
            templateName: template.name,
            notes: nil,
            workoutTemplate: template
        )
        
        template.lastUsed = Date()
        
        guard let templateExercises = template.exercises?.sorted(by: { $0.order < $1.order }), !templateExercises.isEmpty else {
            modelContext.insert(newWorkout)
            try? modelContext.save()
            return
        }
        
        for templateExercise in templateExercises {
            let setsToCreate = max(1, templateExercise.numberOfSets)
            let entry = WorkoutEntry(
                exerciseTemplate: templateExercise.exerciseTemplate,
                exerciseName: templateExercise.exerciseName,
                order: templateExercise.order
            )
            entry.activeWorkout = newWorkout
            
            for setNumber in 1...setsToCreate {
                let restTime = max(0, templateExercise.restTimeSeconds)
                let workoutSet = WorkoutSet(
                    setNumber: setNumber,
                    reps: templateExercise.targetReps,
                    weight: nil,
                    restTime: restTime,
                    completedAt: nil
                )
                workoutSet.workoutEntry = entry
                
                if entry.sets == nil {
                    entry.sets = []
                }
                entry.sets?.append(workoutSet)
                
                modelContext.insert(workoutSet)
            }
            
            if newWorkout.entries == nil {
                newWorkout.entries = []
            }
            newWorkout.entries?.append(entry)
            modelContext.insert(entry)
        }
        
        modelContext.insert(newWorkout)
        try? modelContext.save()
    }
    
    // MARK: - Exercise Management
    
    private func addExercise(name: String, to workout: ActiveWorkout) {
        guard !name.isEmpty else { return }
        
        // Determine next order position
        let currentEntries = workout.entries ?? []
        let nextOrder = currentEntries.isEmpty ? 0 : (currentEntries.map { $0.order }.max() ?? -1) + 1
        
        // Create WorkoutEntry with exercise name snapshot
        let entry = WorkoutEntry(
            exerciseName: name,
            order: nextOrder,
            isWarmup: false
        )
        entry.activeWorkout = workout
        
        // Add entry to workout
        if workout.entries == nil {
            workout.entries = []
        }
        workout.entries?.append(entry)
        
        // Create a default set for the exercise
        let defaultSet = WorkoutSet(setNumber: 1)
        defaultSet.workoutEntry = entry
        
        if entry.sets == nil {
            entry.sets = []
        }
        entry.sets?.append(defaultSet)
        
        // Insert into context and save
        modelContext.insert(entry)
        modelContext.insert(defaultSet)
        try? modelContext.save()
        
        showingAddExercise = false
    }
    
    private func addSet(to entry: WorkoutEntry) {
        let currentSets = entry.sets ?? []
        let nextSetNumber = currentSets.isEmpty ? 1 : (currentSets.map { $0.setNumber }.max() ?? 0) + 1
        
        // Pre-fill weight from previous set of the same exercise
        let sortedSets = currentSets.sorted(by: { $0.setNumber < $1.setNumber })
        let lastSetWithWeight = sortedSets.filter { $0.weight != nil }.last
        let preFilledWeight = lastSetWithWeight?.weight
        
        // Create new set (initially without weight to ensure binding works)
        let newSet = WorkoutSet(setNumber: nextSetNumber)
        newSet.workoutEntry = entry
        
        if entry.sets == nil {
            entry.sets = []
        }
        entry.sets?.append(newSet)
        
        modelContext.insert(newSet)
        
        // Set weight after insertion to ensure SwiftUI binding updates
        if let weight = preFilledWeight {
            newSet.weight = weight
        }
        
        // Save and ensure view updates
        do {
            try modelContext.save()
        } catch {
            print("Error saving new set: \(error)")
        }
    }
    
    private func deleteSet(_ set: WorkoutSet) {
        // Remove set from WorkoutEntry's sets array
        if let entry = set.workoutEntry {
            entry.sets?.removeAll { $0.id == set.id }
        }
        
        // Delete set from ModelContext
        modelContext.delete(set)
        
        // Save context to persist deletion
        try? modelContext.save()
    }
    
    // MARK: - Workout Stopwatch
    
    private func startWorkoutStopwatch() {
        stopWorkoutStopwatch() // Stop any existing timer
        updateWorkoutElapsedTime() // Update immediately
        
        // Use RunLoop to keep timer running even when app backgrounds
        // Update every 0.01 seconds (10ms) for smooth centisecond updates
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [self] _ in
            // Update on main thread but don't block - use async to avoid conflicts with rest timer
            DispatchQueue.main.async {
                self.updateWorkoutElapsedTime()
            }
        }
        // Add to RunLoop to keep it active - use .common mode for better background support
        if let timer = workoutTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    private func stopWorkoutStopwatch() {
        workoutTimer?.invalidate()
        workoutTimer = nil
    }
    
    private func updateWorkoutElapsedTime() {
        guard let workout = activeWorkout else {
            workoutElapsedTime = 0
            return
        }
        workoutElapsedTime = Date().timeIntervalSince(workout.startedAt)
    }
    
    private func formatElapsedTime(_ timeInterval: TimeInterval) -> String {
        let totalCentiseconds = Int(timeInterval * 100) // Convert to centiseconds
        let minutes = totalCentiseconds / 6000
        let seconds = (totalCentiseconds % 6000) / 100
        let centiseconds = totalCentiseconds % 100
        // Use monospaced digits with minimal spacing for consistent width
        return String(format: "%02d:%02d.%02d", minutes, seconds, centiseconds)
    }
    
    private func formatRestTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
    
    // MARK: - Exercise Swipe Navigation Helpers
    // ExerciseView component is now in Views/Components/ExerciseView.swift
    
    
    private func deleteHighestSet(from entry: WorkoutEntry) {
        guard let sets = entry.sets, !sets.isEmpty else { return }
        let sortedSets = sets.sorted(by: { $0.setNumber > $1.setNumber })
        if let highestSet = sortedSets.first {
            deleteSet(highestSet)
        }
    }
    
    private func checkAndAdvanceExercise(entry: WorkoutEntry, workout: ActiveWorkout) {
        // Check if all sets for this exercise are complete
        guard let sets = entry.sets, !sets.isEmpty else { return }
        let allSetsComplete = sets.allSatisfy { $0.completedAt != nil }
        
        if allSetsComplete {
            // Get main exercises (non-warmup)
            guard let entries = workout.entries else { return }
            let mainEntries = entries.filter { $0.isWarmup != true }.sorted(by: { $0.order < $1.order })
            
            // Find current exercise index
            if let currentIndex = mainEntries.firstIndex(where: { $0.id == entry.id }),
               currentIndex + 1 < mainEntries.count {
                // Auto-advance to next exercise after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation {
                        selectedExerciseIndex = currentIndex + 1
                    }
                }
            }
        }
    }
    
    private func calculateExerciseViewHeight(for entry: WorkoutEntry) -> CGFloat {
        let base: CGFloat = 140
        let setHeight: CGFloat = 52
        let buttons: CGFloat = 50

        let count = entry.sets?.count ?? 0
        return base + CGFloat(count) * setHeight + buttons
    }

    
    // MARK: - Finish Workout
    
    private func finishWorkout(_ workout: ActiveWorkout) {
        stopWorkoutStopwatch()
        restTimerManager.stopTimer() // Stop and dismiss rest timer
        let completedAt = Date()
        let durationSeconds = Int(completedAt.timeIntervalSince(workout.startedAt))
        
        // Calculate total volume (sum of reps * weight for all sets)
        var totalVolume: Double = 0.0
        if let entries = workout.entries {
            for entry in entries {
                if let sets = entry.sets {
                    for set in sets {
                        if let reps = set.reps, let weight = set.weight {
                            totalVolume += Double(reps) * weight
                        }
                    }
                }
            }
        }
        
        // Get workout type from template if available
        let workoutType = workout.workoutTemplate?.workoutType
        
        // Create WorkoutHistory
        let history = WorkoutHistory(
            startedAt: workout.startedAt,
            completedAt: completedAt,
            templateName: workout.templateName,
            notes: workout.notes,
            durationSeconds: durationSeconds,
            totalVolume: totalVolume > 0 ? totalVolume : nil,
            workoutType: workoutType,
            isSynced: false
        )
        
        // Copy entries and sets (create new instances for WorkoutHistory)
        if let entries = workout.entries {
            var historyEntries: [WorkoutEntry] = []
            for entry in entries.sorted(by: { $0.order < $1.order }) {
                // Create new WorkoutEntry for history
                let historyEntry = WorkoutEntry(
                    exerciseTemplate: entry.exerciseTemplate,
                    exerciseName: entry.exerciseName,
                    order: entry.order,
                    notes: entry.notes,
                    createdAt: entry.createdAt,
                    isWarmup: entry.isWarmup
                )
                historyEntry.workoutHistory = history
                
                // Copy sets
                if let sets = entry.sets {
                    var historySets: [WorkoutSet] = []
                    for set in sets.sorted(by: { $0.setNumber < $1.setNumber }) {
                        let historySet = WorkoutSet(
                            setNumber: set.setNumber,
                            reps: set.reps,
                            weight: set.weight,
                            restTime: set.restTime,
                            completedAt: set.completedAt,
                            createdAt: set.createdAt
                        )
                        historySet.workoutEntry = historyEntry
                        historySets.append(historySet)
                        modelContext.insert(historySet)
                    }
                    historyEntry.sets = historySets
                }
                
                historyEntries.append(historyEntry)
                modelContext.insert(historyEntry)
            }
            history.entries = historyEntries
        }
        
        // Insert WorkoutHistory
        modelContext.insert(history)
        
        // Delete ActiveWorkout (cascade delete will handle entries and sets)
        modelContext.delete(workout)
        
        // Save all changes
        try? modelContext.save()
        
        // Save workout to HealthKit
        Task {
            do {
                // Estimate calories: roughly 0.04 calories per kg lifted (very rough estimate)
                let estimatedCalories = totalVolume > 0 ? totalVolume * 0.04 : nil
                
                try await HealthKitManager.shared.saveWorkout(
                    startDate: workout.startedAt,
                    endDate: completedAt,
                    duration: TimeInterval(durationSeconds),
                    totalEnergyBurned: estimatedCalories,
                    workoutType: .traditionalStrengthTraining
                )
            } catch {
                print("Failed to save workout to HealthKit: \(error.localizedDescription)")
                // Don't block workout completion if HealthKit save fails
            }
        }
        
        // Dismiss view (navigation back will be handled in Phase 8)
        dismiss()
    }
}

// MARK: - Components extracted to Views/Components/
// SetRowView and AddExerciseSheet are now in separate files for better organization

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ExerciseTemplate.self, ActiveWorkout.self, WorkoutEntry.self, WorkoutSet.self, 
        WorkoutHistory.self, WorkoutTemplate.self, TemplateExercise.self,
        configurations: config
    )
    
    // Create sample exercise templates
    let squatTemplate = ExerciseTemplate(
        name: "Squat",
        category: "Legs",
        muscleGroups: ["Quadriceps", "Glutes"],
        icon: "figure.strengthtraining.traditional",
        iconColor: "#FFD700",
        isFavorite: true
    )
    
    let benchPressTemplate = ExerciseTemplate(
        name: "Bench Press",
        category: "Chest",
        muscleGroups: ["Chest", "Triceps"],
        icon: "figure.strengthtraining.traditional",
        iconColor: "#FF6B6B",
        isFavorite: true
    )
    
    let deadliftTemplate = ExerciseTemplate(
        name: "Deadlift",
        category: "Back",
        muscleGroups: ["Back", "Hamstrings"],
        icon: "figure.strengthtraining.traditional",
        iconColor: "#4ECDC4",
        isFavorite: true
    )
    
    // Create sample workout template
    let workoutTemplate = WorkoutTemplate(
        name: "Push Day",
        notes: "Chest and triceps focus"
    )
    
    // Create sample active workout
    let activeWorkout = ActiveWorkout(
        startedAt: Date().addingTimeInterval(-1800), // Started 30 minutes ago
        templateName: "Push Day",
        workoutTemplate: workoutTemplate
    )
    
    // Create workout entries
    let squatEntry = WorkoutEntry(
        exerciseName: "Squat",
        order: 1,
        isWarmup: false
    )
    squatEntry.activeWorkout = activeWorkout
    squatEntry.exerciseTemplate = squatTemplate
    
    let benchPressEntry = WorkoutEntry(
        exerciseName: "Bench Press",
        order: 2,
        isWarmup: false
    )
    benchPressEntry.activeWorkout = activeWorkout
    benchPressEntry.exerciseTemplate = benchPressTemplate
    
    let deadliftEntry = WorkoutEntry(
        exerciseName: "Deadlift",
        order: 3,
        isWarmup: false
    )
    deadliftEntry.activeWorkout = activeWorkout
    deadliftEntry.exerciseTemplate = deadliftTemplate
    
    // Create sets for Squat
    let squatSet1 = WorkoutSet(setNumber: 1, reps: 5, weight: 100.0, restTime: 90, completedAt: Date().addingTimeInterval(-1200))
    squatSet1.workoutEntry = squatEntry
    
    let squatSet2 = WorkoutSet(setNumber: 2, reps: 5, weight: 100.0, restTime: 90, completedAt: Date().addingTimeInterval(-1100))
    squatSet2.workoutEntry = squatEntry
    
    let squatSet3 = WorkoutSet(setNumber: 3, reps: 5, weight: 100.0, restTime: 90, completedAt: Date().addingTimeInterval(-1000))
    squatSet3.workoutEntry = squatEntry
    
    let squatSet4 = WorkoutSet(setNumber: 4, reps: 5, weight: 100.0, restTime: 90, completedAt: Date().addingTimeInterval(-900))
    squatSet4.workoutEntry = squatEntry
    
    let squatSet5 = WorkoutSet(setNumber: 5, reps: 5, weight: 100.0, restTime: 90)
    squatSet5.workoutEntry = squatEntry
    
    let squatSet6 = WorkoutSet(setNumber: 6, reps: nil, weight: 5.0, restTime: 90)
    squatSet6.workoutEntry = squatEntry
    
    // Create sets for Bench Press
    let benchSet1 = WorkoutSet(setNumber: 1, reps: 8, weight: 80.0, restTime: 90, completedAt: Date().addingTimeInterval(-800))
    benchSet1.workoutEntry = benchPressEntry
    
    let benchSet2 = WorkoutSet(setNumber: 2, reps: 8, weight: 80.0, restTime: 90, completedAt: Date().addingTimeInterval(-700))
    benchSet2.workoutEntry = benchPressEntry
    
    let benchSet3 = WorkoutSet(setNumber: 3, reps: 8, weight: 80.0, restTime: 90)
    benchSet3.workoutEntry = benchPressEntry
    
    // Create sets for Deadlift
    let deadliftSet1 = WorkoutSet(setNumber: 1, reps: 5, weight: 120.0, restTime: 120)
    deadliftSet1.workoutEntry = deadliftEntry
    
    // Insert all data
    container.mainContext.insert(squatTemplate)
    container.mainContext.insert(benchPressTemplate)
    container.mainContext.insert(deadliftTemplate)
    container.mainContext.insert(workoutTemplate)
    container.mainContext.insert(activeWorkout)
    container.mainContext.insert(squatEntry)
    container.mainContext.insert(benchPressEntry)
    container.mainContext.insert(deadliftEntry)
    container.mainContext.insert(squatSet1)
    container.mainContext.insert(squatSet2)
    container.mainContext.insert(squatSet3)
    container.mainContext.insert(squatSet4)
    container.mainContext.insert(squatSet5)
    container.mainContext.insert(squatSet6)
    container.mainContext.insert(benchSet1)
    container.mainContext.insert(benchSet2)
    container.mainContext.insert(benchSet3)
    container.mainContext.insert(deadliftSet1)
    
    // Set up relationships
    activeWorkout.entries = [squatEntry, benchPressEntry, deadliftEntry]
    squatEntry.sets = [squatSet1, squatSet2, squatSet3, squatSet4, squatSet5, squatSet6]
    benchPressEntry.sets = [benchSet1, benchSet2, benchSet3]
    deadliftEntry.sets = [deadliftSet1]
    
    return ActiveWorkoutView()
        .modelContainer(container)
}

