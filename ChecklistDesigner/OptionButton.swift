//
//  OptionButton.swift
//  ChecklistDesigner
//
//  Created by Frode Hjønnevåg on 28/11/2024.
//


import SwiftUI

struct OptionButton: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let option: String
    @Binding var selectedOption: String?
    let isLocked: Bool

    var body: some View {
        Button(action: {
            if !isLocked {
                selectedOption = (selectedOption == option) ? nil : option
            }
        }) {
            Text(option)
                .font(.subheadline)
                .foregroundColor(selectedOption == option ? .white : .blue)
                .padding(8)
                .frame(minWidth: 50)
                .background(selectedOption == option ? Color.blue : (themeManager.isDarkMode ? Color(UIColor.systemGray6) : Color.clear))
                .cornerRadius(5)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(isLocked ? Color.gray : Color.blue, lineWidth: 1)
                )
        }
        .contentShape(Rectangle())
        .disabled(isLocked)
    }
}
