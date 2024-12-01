//
//  CheckboxView.swift
//

import SwiftUI

struct CheckboxView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let option: String
    let selectedOption: Binding<String?>
    let isLocked: Bool
    let onSelect: (String) -> Void
    
    var body: some View {
        Button(action: {
            if !isLocked {
                if selectedOption.wrappedValue == option {
                    selectedOption.wrappedValue = nil
                } else {
                    selectedOption.wrappedValue = option
                    onSelect(option)
                }
                print("Tapped checkbox for \(option). New selected option: \(selectedOption.wrappedValue ?? "nil")")
            }
        }) {
            HStack(spacing: 8) {
                Text(option)
                    .font(.subheadline)
                    .foregroundColor(isLocked ? .gray : (themeManager.isDarkMode ? .white : .primary))

                Image(systemName: selectedOption.wrappedValue == option ? "checkmark.square.fill" : "square")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(selectedOption.wrappedValue == option ? .blue : .gray)
            }
        }
        .buttonStyle(BorderlessButtonStyle())
    }
}
