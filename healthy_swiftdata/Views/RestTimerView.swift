//
//  RestTimerView.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 27/01/2025.
//

import SwiftUI
import Combine
import AVFoundation
import AudioToolbox
import UIKit

// MARK: - Rest Timer Manager

class RestTimerManager: ObservableObject {
    @Published var timeRemaining: Int = 0 // in seconds
    @Published var initialDuration: Int = 0 // in seconds - track starting time for progress calculation
    @Published var isActive: Bool = false
    @Published var isMinimized: Bool = false
    @Published var exerciseName: String = ""
    @Published var setNumber: Int = 0
    
    private var timer: Timer?
    private var notificationManager = NotificationManager.shared
    private var audioPlayer: AVAudioPlayer?
    private var lastBeepTime: Int? = nil // Track last second we beeped to prevent duplicates
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    // Persist timer state for background restoration
    @AppStorage("timerEndDate") private var timerEndDateStorage: Double = 0
    @AppStorage("timerInitialDuration") private var timerInitialDurationStorage: Int = 0
    @AppStorage("timerExerciseName") private var timerExerciseNameStorage: String = ""
    @AppStorage("timerSetNumber") private var timerSetNumberStorage: Int = 0
    @AppStorage("timerIsActive") private var timerIsActiveStorage: Bool = false
    
    func startTimer(seconds: Int, exerciseName: String, setNumber: Int) {
        stopTimer() // Stop any existing timer
        
        self.initialDuration = seconds
        self.timeRemaining = seconds
        self.exerciseName = exerciseName
        self.setNumber = setNumber
        self.isActive = true
        self.isMinimized = false // Reset minimized state when starting new timer
        self.lastBeepTime = nil // Reset beep tracking
        
        // Prepare haptic generator for immediate feedback
        hapticGenerator.prepare()
        
        // Calculate timer end date
        let endDate = Date().addingTimeInterval(TimeInterval(seconds))
        
        // Persist timer state for background restoration
        timerEndDateStorage = endDate.timeIntervalSince1970
        timerInitialDurationStorage = seconds
        timerExerciseNameStorage = exerciseName
        timerSetNumberStorage = setNumber
        timerIsActiveStorage = true
        
        // Schedule notification for timer completion
        notificationManager.scheduleTimerCompletionNotification(
            at: endDate,
            exerciseName: exerciseName,
            setNumber: setNumber
        )
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            // Always update on main thread
            DispatchQueue.main.async {
                self.updateTimer()
            }
        }
        
        // Add to RunLoop with .common mode for better reliability
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    private func updateTimer() {
        // Ensure we're on main thread
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.updateTimer()
            }
            return
        }
        
        // Only decrement if timer is still active and time remaining > 0
        guard self.isActive, self.timeRemaining > 0 else {
            if self.timeRemaining == 0 {
                self.stopTimer()
            }
            return
        }
        
        // Decrement by exactly 1 second
        self.timeRemaining -= 1
        
        // Play beep and vibrate for last 3 seconds
        if self.timeRemaining <= 3 && self.timeRemaining > 0 {
            // Only beep if we haven't beeped for this second yet
            if self.lastBeepTime != self.timeRemaining {
                AudioServicesPlaySystemSound(1057) // System beep sound
                self.hapticGenerator.impactOccurred() // Haptic feedback (works in silent mode)
                self.lastBeepTime = self.timeRemaining
            }
        }
        
        // Stop if reached zero
        if self.timeRemaining == 0 {
            self.stopTimer()
        }
    }
    
    func adjustTime(by seconds: Int) {
        guard isActive else { return }
        
        let newTime = timeRemaining + seconds
        let clampedTime = max(0, newTime)
        
        // Update time remaining
        timeRemaining = clampedTime
        
        // Update initial duration to maintain progress calculation
        // When adding time, increase initial duration by the same amount
        // When subtracting time, decrease initial duration proportionally
        if seconds > 0 {
            // Adding time: extend both time remaining and initial duration
            initialDuration += seconds
        } else {
            // Subtracting time: reduce initial duration by the same amount
            // but ensure it doesn't go below time remaining
            initialDuration = max(timeRemaining, initialDuration + seconds)
        }
        
        // Reset beep tracking when time is adjusted (in case we go back above 3 seconds)
        if timeRemaining > 3 {
            lastBeepTime = nil
        }
        
        // Update persisted end date if timer is active
        if isActive && timeRemaining > 0 {
            // Calculate new end date based on current time + remaining time
            let newEndDate = Date().addingTimeInterval(TimeInterval(timeRemaining))
            timerEndDateStorage = newEndDate.timeIntervalSince1970
            timerInitialDurationStorage = initialDuration // Update stored initial duration
            
            // Reschedule notification with new end time
            notificationManager.cancelTimerNotifications()
            notificationManager.scheduleTimerCompletionNotification(
                at: newEndDate,
                exerciseName: exerciseName,
                setNumber: setNumber
            )
        }
        
        // If time reaches 0, stop the timer
        if timeRemaining == 0 {
            stopTimer()
        }
    }
    
    func minimizeTimer() {
        isMinimized = true
    }
    
    func restoreTimer() {
        isMinimized = false
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isActive = false
        isMinimized = false
        initialDuration = 0
        timeRemaining = 0
        lastBeepTime = nil // Reset beep tracking
        
        // Clear persisted state
        timerEndDateStorage = 0
        timerInitialDurationStorage = 0
        timerExerciseNameStorage = ""
        timerSetNumberStorage = 0
        timerIsActiveStorage = false
        
        // Cancel scheduled notification
        notificationManager.cancelTimerNotifications()
    }
    
    // Restore timer state when app resumes
    func restoreTimerIfNeeded() {
        guard timerIsActiveStorage else { return }
        
        let endDate = Date(timeIntervalSince1970: timerEndDateStorage)
        let now = Date()
        
        // Check if timer should still be active
        if endDate > now {
            // Timer hasn't completed yet
            let remaining = Int(endDate.timeIntervalSince(now))
            self.initialDuration = timerInitialDurationStorage > 0 ? timerInitialDurationStorage : remaining
            self.timeRemaining = remaining
            self.exerciseName = timerExerciseNameStorage
            self.setNumber = timerSetNumberStorage
            self.isActive = true
            self.isMinimized = false
            self.lastBeepTime = nil // Reset beep tracking on restore
            
            // Restart the timer
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                
                // Always update on main thread
                DispatchQueue.main.async {
                    self.updateTimer()
                }
            }
            
            // Add to RunLoop with .common mode for better reliability
            if let timer = timer {
                RunLoop.current.add(timer, forMode: .common)
            }
        } else {
            // Timer has already completed, clear state
            stopTimer()
        }
    }
    
    deinit {
        stopTimer()
    }
}

// MARK: - Rest Timer View

struct RestTimerView: View {
    @ObservedObject var timerManager: RestTimerManager
    let onDismiss: () -> Void
    
    var formattedTime: String {
        let minutes = timerManager.timeRemaining / 60
        let seconds = timerManager.timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header with minimize button
            HStack {
                Spacer()
                Button(action: {
                    timerManager.minimizeTimer()
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            
            // Exercise and set info
            VStack(spacing: 8) {
                Text("Next up:")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                
                Text(timerManager.exerciseName)
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("Set \(timerManager.setNumber)")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            // Timer display with circular progress
            ZStack {
                // Circular progress background
                Circle()
                    .stroke(AppTheme.borderSubtle, lineWidth: 8)
                    .frame(width: 200, height: 200)
                
                // Circular progress fill - shows elapsed time
                if timerManager.timeRemaining > 0 && timerManager.initialDuration > 0 {
                    let progress = 1.0 - (Double(timerManager.timeRemaining) / Double(timerManager.initialDuration))
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            AppTheme.primaryGradient,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1.0), value: timerManager.timeRemaining)
                }
                
                // Timer text
                Text(formattedTime)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                    .monospacedDigit()
            }
            
            // Adjustment buttons
            HStack(spacing: 32) {
                // -15 seconds button
                Button(action: {
                    timerManager.adjustTime(by: -15)
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title)
                        Text("-15s")
                            .font(.caption)
                    }
                    .foregroundColor(AppTheme.gradientOrangeStart)
                    .frame(width: 70, height: 70)
                    .background(AppTheme.gradientOrangeStart.opacity(0.1))
                    .clipShape(Circle())
                }
                
                // +15 seconds button
                Button(action: {
                    timerManager.adjustTime(by: 15)
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                        Text("+15s")
                            .font(.caption)
                    }
                    .foregroundColor(AppTheme.accentPrimary)
                    .frame(width: 70, height: 70)
                    .background(AppTheme.accentPrimary.opacity(0.1))
                    .clipShape(Circle())
                }
            }
            
            // Skip button
            Button(action: onDismiss) {
                Text("Skip Rest")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.cardTertiary)
                    .cornerRadius(AppTheme.cornerRadiusMedium)
            }
        }
        .padding(32)
        .background(AppTheme.cardPrimary)
        .cornerRadius(AppTheme.cornerRadiusLarge)
        .shadow(color: AppTheme.accentPrimary.opacity(0.3), radius: 20, x: 0, y: 10)
        .frame(maxWidth: 350)
        .onChange(of: timerManager.timeRemaining) { oldValue, newValue in
            // Auto-dismiss when timer reaches 0
            if newValue == 0 && timerManager.isActive {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onDismiss()
                }
            }
        }
    }
}

// MARK: - Minimized Timer View

struct MinimizedTimerView: View {
    @ObservedObject var timerManager: RestTimerManager
    let onRestore: () -> Void
    
    var formattedTime: String {
        let minutes = timerManager.timeRemaining / 60
        let seconds = timerManager.timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        Button(action: {
            timerManager.restoreTimer()
            onRestore()
        }) {
            HStack(spacing: 12) {
                Image(systemName: "timer")
                    .font(.title3)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next: \(timerManager.exerciseName)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.textPrimary)
                    Text(formattedTime)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.accentPrimary)
                        .monospacedDigit()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppTheme.cardPrimary)
            .cornerRadius(25)
            .shadow(color: AppTheme.accentPrimary.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Rest Timer Overlay

struct RestTimerOverlay: ViewModifier {
    @ObservedObject var timerManager: RestTimerManager
    let onDismiss: () -> Void
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if timerManager.isActive {
                if timerManager.isMinimized {
                    // Minimized timer view
                    VStack {
                        HStack {
                            Spacer()
                            MinimizedTimerView(timerManager: timerManager) {
                                // onRestore callback - timer will be restored by the view itself
                            }
                            .padding(.trailing, 20)
                            .padding(.top, 20)
                        }
                        Spacer()
                    }
                } else {
                    // Full timer overlay
                    ZStack {
                        // Background overlay
                        AppTheme.background.opacity(0.8)
                            .ignoresSafeArea()
                            .onTapGesture {
                                // Allow tapping outside to minimize
                                timerManager.minimizeTimer()
                            }
                        
                        // Timer card
                        VStack {
                            Spacer()
                            RestTimerView(timerManager: timerManager, onDismiss: onDismiss)
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}

extension View {
    func restTimerOverlay(timerManager: RestTimerManager, onDismiss: @escaping () -> Void) -> some View {
        modifier(RestTimerOverlay(timerManager: timerManager, onDismiss: onDismiss))
    }
}

#Preview {
    struct PreviewWrapper: View {
        @StateObject private var timerManager = RestTimerManager()
        
        var body: some View {
            ZStack {
                Color.gray.opacity(0.2)
                    .ignoresSafeArea()
                
                VStack {
                    Button("Start Timer") {
                        timerManager.startTimer(seconds: 90, exerciseName: "Bench Press", setNumber: 1)
                    }
                    .padding()
                }
                .restTimerOverlay(timerManager: timerManager) {
                    timerManager.stopTimer()
                }
            }
        }
    }
    
    return PreviewWrapper()
}

