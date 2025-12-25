//
//  RestTimerView.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 27/01/2025.
//

import SwiftUI
import Combine

// MARK: - Rest Timer Manager

class RestTimerManager: ObservableObject {
    @Published var timeRemaining: Int = 0 // in seconds
    @Published var isActive: Bool = false
    @Published var isMinimized: Bool = false
    @Published var exerciseName: String = ""
    @Published var setNumber: Int = 0
    
    private var timer: Timer?
    
    func startTimer(seconds: Int, exerciseName: String, setNumber: Int) {
        stopTimer() // Stop any existing timer
        
        self.timeRemaining = seconds
        self.exerciseName = exerciseName
        self.setNumber = setNumber
        self.isActive = true
        self.isMinimized = false // Reset minimized state when starting new timer
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.stopTimer()
                }
            }
        }
    }
    
    func adjustTime(by seconds: Int) {
        let newTime = timeRemaining + seconds
        timeRemaining = max(0, newTime)
        
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
                        .foregroundColor(.secondary)
                }
            }
            
            // Exercise and set info
            VStack(spacing: 8) {
                Text(timerManager.exerciseName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Set \(timerManager.setNumber)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Timer display
            Text(formattedTime)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundColor(.blue)
                .monospacedDigit()
            
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
                    .foregroundColor(.red)
                    .frame(width: 70, height: 70)
                    .background(Color.red.opacity(0.1))
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
                    .foregroundColor(.green)
                    .frame(width: 70, height: 70)
                    .background(Color.green.opacity(0.1))
                    .clipShape(Circle())
                }
            }
            
            // Skip button
            Button(action: onDismiss) {
                Text("Skip Rest")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray)
                    .cornerRadius(12)
            }
        }
        .padding(32)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 10)
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
                    Text(timerManager.exerciseName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text(formattedTime)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                        .monospacedDigit()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(25)
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
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
                        Color.black.opacity(0.4)
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

