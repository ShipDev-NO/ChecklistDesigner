//
//  ChecklistItemView.swift
//

import SwiftUI

struct ChecklistItemView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var shipDetails: ShipDetailsManager
    @Binding var item: ChecklistItem
    let isLocked: Bool
    let checklistId: UUID
    let onShowAreasAndSpaces: (String) -> Void
    
    @State private var searchText = ""
    @State private var selectedTags: [Tag] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch item.type {
            case .locationDetails:
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.bodyText)
                        .font(.body)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if !isLocked {
                        LocationSearchField(
                            searchText: $searchText,
                            selectedTags: Binding(
                                get: { 
                                    // Convert user input to tags
                                    if let text = item.userInput?.text {
                                        return text.split(separator: ",")
                                            .map { String($0.trimmingCharacters(in: .whitespaces)) }
                                            .compactMap { text in
                                                getAllTags().first { $0.text == text }
                                            }
                                    }
                                    return []
                                },
                                set: { tags in
                                    // Convert tags back to user input
                                    let text = tags.map { $0.text }.joined(separator: ", ")
                                    var updatedItem = item
                                    updatedItem.userInput = ChecklistItemUserInput(text: text)
                                    item = updatedItem
                                }
                            ),
                            settings: item.locationSettings ?? LocationSettings(),
                            isLocked: isLocked,
                            onShowAreasAndSpaces: onShowAreasAndSpaces
                        )
                    } else if let userInput = item.userInput?.text {
                        Text(userInput)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            case .descriptionText:
                descriptionTextView
            case .purposeDetails:
                purposeDetailsView
            case .validityDetails:
                validityDetailsView
            case .paragraphHeader:
                paragraphHeaderView
            case .singleLineCheck:
                singleLineCheckView
            case .doubleLineCheck:
                doubleLineCheckView
            }
        }
        .padding()
        .background(Color.white)
    }
    
    private func getAllTags() -> [Tag] {
        var tags: [Tag] = []
        let settings = item.locationSettings ?? LocationSettings()
        
        if settings.allowDeckAreas {
            tags += shipDetails.areasAndSpaces.deckAreas
        }
        if settings.allowEngineSpaces {
            tags += shipDetails.areasAndSpaces.engineSpaces
        }
        if settings.allowEnclosedSpaces {
            tags += shipDetails.areasAndSpaces.enclosedSpaces
        }
        
        return tags
    }
    
    // Description Text View
    private var descriptionTextView: some View {
        Text(item.bodyText)
            .font(.body)
            .bold(item.formatting?.isBold ?? false)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // Purpose Details View
    private var purposeDetailsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.bodyText)
                .font(.body)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if !isLocked {
                TextField("Enter purpose", text: Binding(
                    get: { item.userInput?.text ?? "" },
                    set: { newValue in
                        var updatedItem = item
                        updatedItem.userInput = ChecklistItemUserInput(text: newValue)
                        item = updatedItem
                    }
                ))
                .textFieldStyle(.roundedBorder)
            } else if let userInput = item.userInput?.text {
                Text(userInput)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    // Validity Details View
    private var validityDetailsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.bodyText)
                .font(.body)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if !isLocked {
                VStack(alignment: .leading, spacing: 8) {
                    DatePicker("Valid from", selection: Binding(
                        get: { item.validityStartDate ?? Date() },
                        set: { newValue in
                            var updatedItem = item
                            updatedItem.validityStartDate = newValue
                            item = updatedItem
                        }
                    ), displayedComponents: [.date, .hourAndMinute])
                    
                    if let maxHours = item.maxValidityHours {
                        Stepper(
                            "Duration: \(item.validityDurationHours ?? 1) hours",
                            value: Binding(
                                get: { item.validityDurationHours ?? 1 },
                                set: { newValue in
                                    var updatedItem = item
                                    updatedItem.validityDurationHours = newValue
                                    item = updatedItem
                                }
                            ),
                            in: 1...maxHours
                        )
                    }
                }
            } else if let startDate = item.validityStartDate,
                      let endDate = item.validityEndDate {
                Text("Valid: \(formattedDateTime(startDate)) - \(formattedDateTime(endDate))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // Paragraph Header View
    private var paragraphHeaderView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.headerText)
                .font(.title2)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let supportText = item.supportText, !supportText.isEmpty {
                Text(supportText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    // Single Line Check View
    private var singleLineCheckView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.bodyText)
                .font(.body)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            checkboxOptionsView
        }
    }
    
    // Double Line Check View
    private var doubleLineCheckView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.bodyText)
                .font(.body)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let supportText = item.supportText {
                Text(supportText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            checkboxOptionsView
        }
    }
    
    private var checkboxOptionsView: some View {
        Group {
            if let checkOptions = item.checkOptions {
                HStack(spacing: 16) {
                    Spacer()
                    if checkOptions.yes {
                        CheckboxView(
                            option: "Yes",
                            selectedOption: Binding(
                                get: { item.selectedOption },
                                set: { newValue in
                                    var updatedItem = item
                                    updatedItem.selectedOption = newValue
                                    item = updatedItem
                                }
                            ),
                            isLocked: isLocked,
                            onSelect: { _ in }
                        )
                    }
                    if checkOptions.no {
                        CheckboxView(
                            option: "No",
                            selectedOption: Binding(
                                get: { item.selectedOption },
                                set: { newValue in
                                    var updatedItem = item
                                    updatedItem.selectedOption = newValue
                                    item = updatedItem
                                }
                            ),
                            isLocked: isLocked,
                            onSelect: { _ in }
                        )
                    }
                    if checkOptions.na {
                        CheckboxView(
                            option: "N/A",
                            selectedOption: Binding(
                                get: { item.selectedOption },
                                set: { newValue in
                                    var updatedItem = item
                                    updatedItem.selectedOption = newValue
                                    item = updatedItem
                                }
                            ),
                            isLocked: isLocked,
                            onSelect: { _ in }
                        )
                    }
                }
            }
        }
    }
    
    private func formattedDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter.string(from: date)
    }
}
