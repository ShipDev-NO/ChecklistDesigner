//
//  ChecklistEditorView.swift
//  ChecklistDesigner
//
//  Created by Frode Hjønnevåg on 27/11/2024.
//

import SwiftUI

struct ChecklistEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @Binding var checklist: Checklist
    let onSave: () -> Void
    
    @State private var isEditingHeader = false
    @State private var showingItemGallery = false
    @State private var isCreatingNewChecklistItem = false
    @State private var selectedChecklistItemIndex: Int?
    @State private var newChecklistItem = ChecklistItem()
    
    @State private var editedName: String
    @State private var editedSubtitle: String
    @State private var editedRevisionNumber: String
    @State private var editedRevisionDate: Date
    @State private var editedApprovedBy: String
    
    init(checklist: Binding<Checklist>, onSave: @escaping () -> Void) {
        self._checklist = checklist
        self.onSave = onSave
        
        // Initialize state from the binding's current value
        let currentChecklist = checklist.wrappedValue
        self._editedName = State(initialValue: currentChecklist.name)
        self._editedSubtitle = State(initialValue: currentChecklist.subtitle)
        self._editedRevisionNumber = State(initialValue: String(currentChecklist.revisionNumber))
        self._editedRevisionDate = State(initialValue: currentChecklist.revisionDate)
        self._editedApprovedBy = State(initialValue: currentChecklist.approvedBy)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Header with Template Details
            VStack(spacing: 0) {
                // App Header
                HStack {
                    Text("Edit Template")
                        .viewTitleStyle()
                    Spacer()
                    Button("Done") {
                        saveChanges()
                    }
                    .foregroundColor(.white)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                Divider()
                    .background(.white.opacity(0.3))
                
                // Template Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(checklist.name)
                            .font(.title3)
                            .bold()
                            .foregroundColor(.white)
                        if !checklist.subtitle.isEmpty {
                            Text(checklist.subtitle)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        HStack(spacing: 16) {
                            Text("Rev \(String(format: "%02d", checklist.revisionNumber))")
                            Text("•")
                            Text(formattedDate(checklist.revisionDate))
                            if !checklist.approvedBy.isEmpty {
                                Text("•")
                                Text(checklist.approvedBy)
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                    Button {
                        isEditingHeader = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .background(Color(red: 0.1, green: 0.1, blue: 0.2))
            
            List {
                // Template Items Section
                Section {
                    ForEach(checklist.items) { item in
                        itemRow(for: item)
                    }
                    .onDelete(perform: deleteItems)
                    .onMove(perform: moveItems)
                } header: {
                    Text("Template Items")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .textCase(nil)
                }
            }
            .listStyle(.plain)
            
            // Add Item Button
            if checklist.items.count < 100 {
                Button(action: {
                    showingItemGallery = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                            .font(.headline)
                        Text("Add Item")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(red: 0.1, green: 0.1, blue: 0.2))
                }
            }
        }
        .background(themeManager.backgroundColor)
        .sheet(isPresented: $isEditingHeader) {
            headerEditSheet
        }
        // ... rest of your sheets ...
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
    }
    
    private func saveChanges() {
        print("\n=== SAVE TEMPLATE CHANGES ===")
        print("Saving template: \(checklist.name)")
        
        onSave()
        dismiss()
        
        print("=== SAVE TEMPLATE CHANGES COMPLETE ===\n")
    }
    
    private func itemRow(for item: ChecklistItem) -> some View {
        Button {
            newChecklistItem = item
            selectedChecklistItemIndex = checklist.items.firstIndex(where: { $0.id == item.id })
            isCreatingNewChecklistItem = true
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(titleForItem(item))
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                HStack(spacing: 16) {
                    Text("Item Type: \(itemTypeDescription(item.type))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        var updatedChecklist = checklist
        updatedChecklist.items.remove(atOffsets: offsets)
        checklist = updatedChecklist
    }
    
    private func moveItems(from source: IndexSet, to destination: Int) {
        var updatedChecklist = checklist
        updatedChecklist.items.move(fromOffsets: source, toOffset: destination)
        checklist = updatedChecklist
    }
    
    private var headerEditSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 0) {
                    HStack {
                        Text("Edit Template Details")
                            .viewTitleStyle()
                        Spacer()
                        Button("Done") {
                            saveHeaderChanges()
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
                    Section("Template Details") {
                        TextField("Name", text: $editedName)
                        TextField("Subtitle", text: $editedSubtitle)
                    }
                    
                    Section("Revision Information") {
                        TextField("Revision Number", text: $editedRevisionNumber)
                            .keyboardType(.numberPad)
                        DatePicker("Revision Date", selection: $editedRevisionDate, displayedComponents: .date)
                        TextField("Approved By", text: $editedApprovedBy)
                    }
                }
                .listStyle(.plain)
            }
            .background(themeManager.backgroundColor)
        }
    }
    
    private func saveHeaderChanges() {
        print("\n=== SAVE HEADER CHANGES ===")
        print("Before update:")
        print("Current name: \(checklist.name)")
        
        // Create new checklist with updated values
        var updatedChecklist = Checklist(
            id: checklist.id,
            name: editedName,
            subtitle: editedSubtitle,
            revisionNumber: Int(editedRevisionNumber) ?? checklist.revisionNumber,
            revisionDate: editedRevisionDate,
            approvedBy: editedApprovedBy,
            items: checklist.items,
            state: .template,
            serialNumber: checklist.serialNumber
        )
        
        print("After update:")
        print("New name: \(updatedChecklist.name)")
        
        // Update through binding
        checklist = updatedChecklist
        
        // Close header edit sheet
        isEditingHeader = false
        
        print("=== SAVE HEADER CHANGES COMPLETE ===\n")
    }
    
    private func updateChecklist(_ newChecklist: Checklist) {
        print("ChecklistEditorView - Updating checklist: \(newChecklist.name)")
        checklist = newChecklist
        onSave()
    }
    
    private func titleForItem(_ item: ChecklistItem) -> String {
        switch item.type {
        case .descriptionText:
            return item.bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        case .locationDetails, .purposeDetails, .validityDetails:
            return item.bodyText
        case .paragraphHeader:
            return item.headerText
        case .singleLineCheck, .doubleLineCheck:
            return item.bodyText
        }
    }
    
    private func itemTypeDescription(_ type: ChecklistItemType) -> String {
        switch type {
        case .descriptionText: return "Description Text"
        case .locationDetails: return "Location Details"
        case .purposeDetails: return "Purpose Details"
        case .validityDetails: return "Validity Details"
        case .paragraphHeader: return "Paragraph Header"
        case .singleLineCheck: return "Single Line Check"
        case .doubleLineCheck: return "Double Line Check"
        }
    }
}
