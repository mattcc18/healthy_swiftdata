//
//  AppTheme.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 27/01/2025.
//

import SwiftUI
import Combine

/// Theme mode enum
enum ThemeMode: String, CaseIterable {
    case dark = "dark"
    case light = "light"
}

/// Theme Manager
class ThemeManager: ObservableObject {
    @AppStorage("themeMode") var themeMode: ThemeMode = .dark {
        didSet {
            objectWillChange.send()
        }
    }
    
    static let shared = ThemeManager()
    
    var currentTheme: AppTheme.Theme {
        themeMode == .dark ? AppTheme.darkGreen : AppTheme.lightRevolut
    }
}

/// Centralized color theme and styling constants
struct AppTheme {
    
    // MARK: - Theme Management
    
    private static let themeManager = ThemeManager.shared
    
    static var themeMode: ThemeMode {
        get { themeManager.themeMode }
        set { themeManager.themeMode = newValue }
    }
    
    static var currentTheme: Theme {
        themeManager.currentTheme
    }
    
    // MARK: - Theme Definitions
    
    struct Theme {
        // Background Colors
        let background: Color
        let cardPrimary: Color
        let cardSecondary: Color
        let cardTertiary: Color
        
        // Accent Colors
        let accentPrimary: Color
        let accentSecondary: Color
        let accentTertiary: Color
        
        // Gradient Colors
        let gradientOrangeStart: Color
        let gradientOrangeMiddle: Color
        let gradientOrangeEnd: Color
        let gradientCyan: Color
        
        // Text Colors
        let textPrimary: Color
        let textSecondary: Color
        let textTertiary: Color
        let textMuted: Color
        
        // Border Colors
        let borderSubtle: Color
        let borderMedium: Color
        let borderStrong: Color
        
        // Gradients
        var primaryGradient: LinearGradient {
            LinearGradient(
                colors: [accentPrimary, accentSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        var orangeGradient: LinearGradient {
            LinearGradient(
                colors: [gradientOrangeStart, gradientOrangeMiddle, gradientOrangeEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        var cyanGradient: LinearGradient {
            LinearGradient(
                colors: [gradientCyan, gradientCyan.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        
        var greenGradient: LinearGradient {
            LinearGradient(
                colors: [accentSecondary, accentTertiary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // MARK: - Dark Green Theme (Current)
    
    static let darkGreen = Theme(
        background: Color(hex: 0x0A0A0A),
        cardPrimary: Color(hex: 0x1A1A1A),
        cardSecondary: Color(hex: 0x1C1C1E),
        cardTertiary: Color(hex: 0x2A2A2A),
        accentPrimary: Color(hex: 0xD4FF00),
        accentSecondary: Color(hex: 0x8FE600),
        accentTertiary: Color(hex: 0x4ADE80),
        gradientOrangeStart: Color(hex: 0xFF6B35),
        gradientOrangeMiddle: Color(hex: 0xFF8E53),
        gradientOrangeEnd: Color(hex: 0xFFA07A),
        gradientCyan: Color(hex: 0x4DD0E1),
        textPrimary: .white,
        textSecondary: Color.white.opacity(0.7),
        textTertiary: Color.white.opacity(0.4),
        textMuted: Color(hex: 0x8E8E93),
        borderSubtle: Color.white.opacity(0.05),
        borderMedium: Color.white.opacity(0.1),
        borderStrong: Color.white.opacity(0.2)
    )
    
    // MARK: - Light Revolut Theme
    
    static let lightRevolut = Theme(
        background: Color(hex: 0xFFFFFF),
        cardPrimary: Color(hex: 0xF5F5F7),
        cardSecondary: Color(hex: 0xF8F8FA),
        cardTertiary: Color(hex: 0xE9EBEF),
        accentPrimary: Color(hex: 0xFF3B30), // Red accent
        accentSecondary: Color(hex: 0xFF6B6B), // Lighter red
        accentTertiary: Color(hex: 0xFF8E8E), // Light red
        gradientOrangeStart: Color(hex: 0xFF6B35),
        gradientOrangeMiddle: Color(hex: 0xFF8E53),
        gradientOrangeEnd: Color(hex: 0xFFA07A),
        gradientCyan: Color(hex: 0xFF6B6B), // Red accent
        textPrimary: Color(hex: 0x1D1D1F),
        textSecondary: Color(hex: 0x6E6E73),
        textTertiary: Color(hex: 0x86868B),
        textMuted: Color(hex: 0xAEAEB2),
        borderSubtle: Color.black.opacity(0.05),
        borderMedium: Color.black.opacity(0.1),
        borderStrong: Color.black.opacity(0.2)
    )
    
    // MARK: - Convenience Properties (Current Theme)
    
    static var background: Color { currentTheme.background }
    static var cardPrimary: Color { currentTheme.cardPrimary }
    static var cardSecondary: Color { currentTheme.cardSecondary }
    static var cardTertiary: Color { currentTheme.cardTertiary }
    static var accentPrimary: Color { currentTheme.accentPrimary }
    static var accentSecondary: Color { currentTheme.accentSecondary }
    static var accentTertiary: Color { currentTheme.accentTertiary }
    static var gradientOrangeStart: Color { currentTheme.gradientOrangeStart }
    static var gradientOrangeMiddle: Color { currentTheme.gradientOrangeMiddle }
    static var gradientOrangeEnd: Color { currentTheme.gradientOrangeEnd }
    static var gradientCyan: Color { currentTheme.gradientCyan }
    static var textPrimary: Color { currentTheme.textPrimary }
    static var textSecondary: Color { currentTheme.textSecondary }
    static var textTertiary: Color { currentTheme.textTertiary }
    static var textMuted: Color { currentTheme.textMuted }
    static var borderSubtle: Color { currentTheme.borderSubtle }
    static var borderMedium: Color { currentTheme.borderMedium }
    static var borderStrong: Color { currentTheme.borderStrong }
    static var primaryGradient: LinearGradient { currentTheme.primaryGradient }
    static var orangeGradient: LinearGradient { currentTheme.orangeGradient }
    static var cyanGradient: LinearGradient { currentTheme.cyanGradient }
    static var greenGradient: LinearGradient { currentTheme.greenGradient }
    
    // MARK: - Corner Radius Constants (Bubbly Design)
    
    static let cornerRadiusExtraLarge: CGFloat = 28
    static let cornerRadiusLarge: CGFloat = 24
    static let cornerRadiusMedium: CGFloat = 20
    static let cornerRadiusSmall: CGFloat = 16
    
    // MARK: - Shadow Helpers
    
    static func shadowAccentPrimary(opacity: Double = 0.2, radius: CGFloat = 10) -> Color {
        accentPrimary.opacity(opacity)
    }
    
    static func shadowOrange(opacity: Double = 0.3, radius: CGFloat = 10) -> Color {
        gradientOrangeStart.opacity(opacity)
    }
}

// MARK: - ThemeMode Extension

extension ThemeMode {
    var displayName: String {
        switch self {
        case .dark: return "Dark Green"
        case .light: return "Light Revolut"
        }
    }
}

// MARK: - Color Extension for Hex Values

extension Color {
    /// Initialize Color from hex value
    /// - Parameter hex: Hex value (e.g., 0xD4FF00)
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}
