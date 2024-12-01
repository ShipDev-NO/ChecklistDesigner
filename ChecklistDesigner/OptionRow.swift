//
//  OptionRow.swift
//  ChecklistDesigner
//
//  Created by Frode Hjønnevåg on 28/11/2024.
//


import SwiftUI

struct OptionRow: View {
    let option: String
    @Binding var selectedOption: String?
    let isLocked: Bool

    var body: some View {
        HStack {
            Toggle(isOn: Binding(
                get: { selectedOption == option },
                set: { newValue in
                    if newValue {
                        selectedOption = option
                    } else {
                        selectedOption = nil
                    }
                }
            )) {
                Text(option)
                    .font(.subheadline)
                    .foregroundColor(isLocked ? .gray : .primary)
            }
            .disabled(isLocked) // Disable toggle if locked
        }
        .padding(.vertical, 5)
    }
}