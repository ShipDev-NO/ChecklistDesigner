//
//  ChecklistItemEditorView.swift
//  ChecklistDesigner
//
//  Created by Frode Hjønnevåg on 28/11/2024.
//

import SwiftUI

struct ChecklistItemEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @Binding var checklistItem: ChecklistItem
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 0) {
                HStack {
                    Text(isEditing ? "Edit Item" : "New Item")
                        .viewTitleStyle()
                    Spacer()
                    Button("Done") {
                        onSave()
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                Divider()
                    .background(.white.opacity(0.3))
            }
            .background(Color(red: 0.1, green: 0.1, blue: 0.2))
            
            List {
                // Common fields
                if checklistItem.type == .locationDetails {
                    Section {
                        TextField("Location Title Text", text: $checklistItem.bodyText)
                    }
                    
                    Section("Allowed Areas and Spaces") {
                        Toggle("Deck Areas and Spaces", isOn: Binding(
                            get: { checklistItem.locationSettings?.allowDeckAreas ?? true },
                            set: { newValue in
                                var settings = checklistItem.locationSettings ?? LocationSettings()
                                settings.allowDeckAreas = newValue
                                checklistItem.locationSettings = settings
                            }
                        ))
                        
                        Toggle("Engine and Accommodation Spaces", isOn: Binding(
                            get: { checklistItem.locationSettings?.allowEngineSpaces ?? true },
                            set: { newValue in
                                var settings = checklistItem.locationSettings ?? LocationSettings()
                                settings.allowEngineSpaces = newValue
                                checklistItem.locationSettings = settings
                            }
                        ))
                        
                        Toggle("Enclosed Spaces", isOn: Binding(
                            get: { checklistItem.locationSettings?.allowEnclosedSpaces ?? true },
                            set: { newValue in
                                var settings = checklistItem.locationSettings ?? LocationSettings()
                                settings.allowEnclosedSpaces = newValue
                                checklistItem.locationSettings = settings
                            }
                        ))
                        
                        Stepper(
                            "Maximum Locations: \(checklistItem.locationSettings?.maxLocations ?? 1)",
                            value: Binding(
                                get: { checklistItem.locationSettings?.maxLocations ?? 1 },
                                set: { newValue in
                                    var settings = checklistItem.locationSettings ?? LocationSettings()
                                    settings.maxLocations = newValue
                                    checklistItem.locationSettings = settings
                                }
                            ),
                            in: 1...10
                        )
                    }
                } else {
                    Section {
                        TextField("Body Text", text: $checklistItem.bodyText)
                        if checklistItem.type == .doubleLineCheck {
                            TextField("Support Text", text: Binding(
                                get: { checklistItem.supportText ?? "" },
                                set: { checklistItem.supportText = $0 }
                            ))
                        }
                    }
                }
                
                // ... rest of your existing sections ...
            }
            .listStyle(.plain)
        }
        .background(themeManager.backgroundColor)
    }
    
    private var isEditing: Bool {
        checklistItem.id != UUID()
    }
}
