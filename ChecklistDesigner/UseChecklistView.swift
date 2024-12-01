//
//  UseChecklistView.swift
//

import SwiftUI

struct UseChecklistView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var checklist: Checklist
    let onComplete: (Checklist) -> Void
    let onDismiss: (Bool) -> Void
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var shipDetails: ShipDetailsManager
    @State private var hasInteracted: Bool = false
    @State private var showingDeleteWarning = false
    @State private var showingPrintPreview = false
    @State private var showingAreasAndSpaces = false
    @State private var pendingLocationSearch: String = ""
    @State private var navigationPath = NavigationPath()
    @State private var itemToUpdate: ChecklistItem?
    @GestureState private var dragOffset = CGSize.zero
    @State private var offset = CGSize.zero
    @State private var lastTagUpdate: Date = .distantPast

    // Add timer for checking recent tags
    private let tagCheckTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        headerView
                            .gesture(
                                DragGesture()
                                    .updating($dragOffset) { value, state, _ in
                                        if value.translation.height > 0 {  // Only allow downward drag
                                            state = value.translation
                                        }
                                    }
                                    .onEnded { value in
                                        if value.translation.height > 100 {  // Threshold for dismissal
                                            onComplete(checklist)  // Save before dismissing
                                            onDismiss(true)
                                            dismiss()
                                        } else {
                                            withAnimation {
                                                offset = .zero
                                            }
                                        }
                                    }
                            )
                        
                        Divider()

                        // Checklist items
                        LazyVStack(spacing: 0, pinnedViews: []) {
                            ForEach($checklist.items) { $item in
                                VStack(spacing: 0) {
                                    ChecklistItemView(
                                        item: $item, 
                                        isLocked: checklist.state == .completed,
                                        checklistId: checklist.id,
                                        onShowAreasAndSpaces: { searchText in
                                            pendingLocationSearch = searchText
                                            itemToUpdate = item
                                            showingAreasAndSpaces = true
                                        }
                                    )
                                    Divider()
                                }
                            }
                        }
                    }
                }

                // Completion button section
                if checklist.state == .inProgress {
                    Button(action: markChecklistAsCompleted) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.headline)
                            Text("Mark as Completed")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isChecklistComplete ? Color(red: 0.1, green: 0.1, blue: 0.2) : Color.gray)
                    }
                    .disabled(!isChecklistComplete)
                } else if checklist.state == .completed {
                    Text("Completed \(formattedDate(checklist.completionDate))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .navigationDestination(isPresented: $showingAreasAndSpaces) {
                NavigationStack {
                    AreasAndSpacesView(shipDetails: shipDetails)
                        .standardSheet()
                }
                .navigationTitle("Areas and Spaces")
                .navigationBarTitleDisplayMode(.inline)
            }
            .navigationBarTitleDisplayMode(.inline)
            .background(themeManager.backgroundColor)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            onDismiss(true)
                            dismiss()
                        }) {
                            Label("Close", systemImage: "xmark.circle")
                        }
                        
                        Button(action: {
                            showingPrintPreview = true
                        }) {
                            Label("Print", systemImage: "printer")
                        }
                        
                        Button(role: .destructive, action: {
                            showingDeleteWarning = true
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                }
            }
            .alert("Delete Checklist?", isPresented: $showingDeleteWarning) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    onDismiss(false)
                    dismiss()
                }
            } message: {
                Text("This checklist will be permanently deleted. This action cannot be undone.")
            }
            .sheet(isPresented: $showingPrintPreview) {
                PrintPreviewView(checklist: checklist)
            }
            .interactiveDismissDisabled(!checklist.items.isEmpty)
            .onDisappear {
                onDismiss(true)
                onComplete(checklist)  // Save all changes
            }
            .offset(y: offset.height + dragOffset.height)
        }
        .onReceive(tagCheckTimer) { _ in
            checkForRecentTags()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("UpdateSelectedTags"))) { notification in
            // Debounce rapid updates
            let now = Date()
            guard now.timeIntervalSince(lastTagUpdate) > 0.5 else { return }
            lastTagUpdate = now
            
            guard let userInfo = notification.userInfo,
                  let tag = userInfo["tag"] as? Tag,
                  let itemId = userInfo["itemId"] as? UUID,
                  let checklistId = userInfo["checklistId"] as? UUID,
                  checklistId == checklist.id,
                  let index = checklist.items.firstIndex(where: { $0.id == itemId }) else { return }
            
            var updatedChecklist = checklist
            var updatedItem = updatedChecklist.items[index]
            updatedItem.userInput = ChecklistItemUserInput(text: tag.text)
            updatedChecklist.items[index] = updatedItem
            checklist = updatedChecklist
            onComplete(updatedChecklist)  // Save immediately
        }
    }

    private var headerView: some View {
        VStack(spacing: 16) {
            Text(checklist.name)
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
            
            if !checklist.subtitle.isEmpty {
                Text(checklist.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 16) {
                Spacer()
                metadataItem(icon: "number", text: "Rev \(String(format: "%02d", checklist.revisionNumber))")
                metadataItem(icon: "calendar", text: formattedDateShort(checklist.revisionDate))
                if !checklist.approvedBy.isEmpty {
                    metadataItem(icon: "person", text: checklist.approvedBy)
                }
                Spacer()
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.systemGray6))
    }

    private func metadataItem(icon: String, text: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption)
            .foregroundColor(.secondary)
    }

    private func markChecklistAsCompleted() {
        var updatedChecklist = checklist
        updatedChecklist.state = .completed
        updatedChecklist.completionDate = Date()
        
        onComplete(updatedChecklist)
        dismiss()
    }

    private var isChecklistComplete: Bool {
        // Filter items that require input and check if they all have selections
        let itemsRequiringInput = checklist.items.filter { item in
            switch item.type {
            case .singleLineCheck, .doubleLineCheck:
                return true // These require checkbox selection
            case .locationDetails, .purposeDetails:
                return true // These require user text input
            case .descriptionText, .paragraphHeader, .validityDetails:
                return false // These are informational only
            }
        }
        
        // If no items require input, consider the checklist complete
        guard !itemsRequiringInput.isEmpty else { return true }
        
        // Check if all required items have input
        return itemsRequiringInput.allSatisfy { item in
            switch item.type {
            case .singleLineCheck, .doubleLineCheck:
                return item.selectedOption != nil
            case .locationDetails, .purposeDetails:
                return item.userInput?.text?.isEmpty == false
            default:
                return true
            }
        }
    }

    private func formattedDateShort(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter.string(from: date)
    }

    private func getAllTags() -> [Tag] {
        shipDetails.areasAndSpaces.deckAreas +
        shipDetails.areasAndSpaces.engineSpaces +
        shipDetails.areasAndSpaces.enclosedSpaces
    }

    // Add function to check for recent tags
    private func checkForRecentTags() {
        // Get all tags sorted by creation time
        let allTags = getAllTags().sorted { $0.createdAt > $1.createdAt }
        
        // Check if there's a recent tag (within last minute)
        if let mostRecentTag = allTags.first,
           Date().timeIntervalSince(mostRecentTag.createdAt) <= 60 { // 60 seconds = 1 minute
            
            // Only update if this checklist is in progress
            guard checklist.state == .inProgress else { return }
            
            // Find first empty location detail item
            if let index = checklist.items.firstIndex(where: { item in
                item.type == .locationDetails && (item.userInput?.text?.isEmpty ?? true)
            }) {
                // Update the item
                var updatedChecklist = checklist
                var updatedItem = updatedChecklist.items[index]
                updatedItem.userInput = ChecklistItemUserInput(text: mostRecentTag.text)
                updatedChecklist.items[index] = updatedItem
                checklist = updatedChecklist
                
                // Notify the ChecklistItemView
                NotificationCenter.default.post(
                    name: Notification.Name("UpdateSelectedTags"),
                    object: nil,
                    userInfo: [
                        "tag": mostRecentTag,
                        "itemId": updatedItem.id as Any,
                        "checklistId": checklist.id as Any
                    ]
                )
                
                print("Updated empty location item \(updatedItem.id) in checklist \(checklist.id) with tag: \(mostRecentTag.text)")
            }
        }
    }

    private func updateChecklistItem(_ item: ChecklistItem, at index: Int) {
        var updatedChecklist = checklist
        updatedChecklist.items[index] = item
        checklist = updatedChecklist
        onComplete(updatedChecklist)  // Save changes immediately
    }

    // Add this method to handle checkbox changes
    private func handleCheckboxChange(_ item: ChecklistItem, option: String) {
        if let index = checklist.items.firstIndex(where: { $0.id == item.id }) {
            var updatedItem = item
            updatedItem.selectedOption = option
            updateChecklistItem(updatedItem, at: index)
        }
    }

    // Add this method to handle time changes
    private func handleTimeChange(_ item: ChecklistItem, hours: Int) {
        if let index = checklist.items.firstIndex(where: { $0.id == item.id }) {
            var updatedItem = item
            updatedItem.validityDurationHours = hours
            updateChecklistItem(updatedItem, at: index)
        }
    }

    // Add this to handle any input changes
    private func handleInputChange(_ item: ChecklistItem, text: String) {
        if let index = checklist.items.firstIndex(where: { $0.id == item.id }) {
            var updatedItem = item
            updatedItem.userInput = ChecklistItemUserInput(text: text)
            updateChecklistItem(updatedItem, at: index)
        }
    }

    // Add this to handle tag selection
    private func handleTagSelection(_ item: ChecklistItem, tag: Tag) {
        if let index = checklist.items.firstIndex(where: { $0.id == item.id }) {
            var updatedItem = item
            updatedItem.userInput = ChecklistItemUserInput(text: tag.text)
            updateChecklistItem(updatedItem, at: index)
        }
    }
}
