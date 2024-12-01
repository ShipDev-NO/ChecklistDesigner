//
//  ThemeManager.swift
//

import SwiftUI

class ThemeManager: ObservableObject {
    @AppStorage("isDarkMode") var isDarkMode: Bool = false
    
    // Add any additional theme-related properties and methods here
    var backgroundColor: Color {
        isDarkMode ? .black : Color(UIColor.systemGroupedBackground)
    }
    
    var secondaryBackgroundColor: Color {
        isDarkMode ? Color(UIColor.systemGray6) : .white
    }
    
    var textColor: Color {
        isDarkMode ? .white : .primary
    }
    
    var secondaryTextColor: Color {
        isDarkMode ? .gray : .secondary
    }
} 