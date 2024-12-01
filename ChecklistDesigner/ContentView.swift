//
//  ContentView.swift
//

import SwiftUI
import UniformTypeIdentifiers

struct IdentifiableIndex: Identifiable {
    let id: Int
    
    init(_ index: Int) {
        self.id = index
    }
}

struct ContentView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var checklists: [Checklist] = []
    @State private var newChecklistName: String = ""
    @State private var isAddingNewChecklist = false
    @State private var selectedChecklistForEditing: Checklist? = nil
    @State private var activeChecklistIndex: IdentifiableIndex? = nil
    @State private var showingDeleteConfirmation = false
    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    @State private var showingDeleteAlert = false
    @State private var deletedSerialNumbers: Set<String> = Set(UserDefaults.standard.stringArray(forKey: "deletedSerialNumbers") ?? [])
    @State private var showingSettingsSheet = false
    @State private var showingDeleteAllConfirmation = false
    @StateObject private var shipDetails = ShipDetailsManager()
    
    private let persistence = ChecklistPersistence()
    private let templateManager: TemplateManaging
    
    init() {
        self.templateManager = TemplateManager(persistence: ChecklistPersistence())
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerView
                checklistsList
            }
            .background(themeManager.isDarkMode ? Color.black : Color(UIColor.systemGray6))
        }
        .fileExporter(
            isPresented: $showingExportSheet,
            document: ChecklistDocument(checklists: checklists),
            contentType: .json,
            defaultFilename: "checklists.json"
        ) { result in
            if case .success(let url) = result {
                print("Saved to \(url)")
            }
        }
        .fileImporter(
            isPresented: $showingImportSheet,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result {
                guard let url = urls.first else { return }
                importChecklists(from: url)
            }
        }
        .alert("Delete Checklist?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let checklist = selectedChecklistForEditing {
                    deleteChecklist(checklist)
                }
            }
        } message: {
            Text("Are you sure you want to delete this checklist? This action cannot be undone.")
        }
        .alert("Delete All Data?", isPresented: $showingDeleteAllConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAllData()
            }
        } message: {
            Text("This will delete all templates, checklists, and settings. This action cannot be undone.")
        }
        .sheet(isPresented: $isAddingNewChecklist) {
            NavigationStack {
                Form {
                    TextField("Template Name", text: $newChecklistName)
                }
                .navigationTitle("New Template")
                .navigationBarTitleDisplayMode(.inline)
                .safeAreaInset(edge: .bottom) {
                    HStack {
                        Button("Cancel") {
                            newChecklistName = ""
                            isAddingNewChecklist = false
                        }
                        Spacer()
                        Button("Create") {
                            addNewChecklist()
                            isAddingNewChecklist = false
                        }
                        .disabled(newChecklistName.isEmpty)
                    }
                    .padding()
                }
            }
        }
        .sheet(item: $selectedChecklistForEditing) { checklist in
            NavigationStack {
                ChecklistEditorView(
                    checklist: Binding(
                        get: { 
                            if let index = checklists.firstIndex(where: { $0.id == checklist.id }) {
                                return checklists[index]
                            }
                            return checklist
                        },
                        set: { updatedChecklist in
                            if let index = checklists.firstIndex(where: { $0.id == checklist.id }) {
                                checklists[index] = updatedChecklist
                                persistence.save(checklists)
                            }
                        }
                    ),
                    onSave: {
                        loadData()
                        selectedChecklistForEditing = nil
                    }
                )
                .interactiveDismissDisabled()
            }
        }
        .sheet(item: $activeChecklistIndex) { index in
            NavigationStack {
                UseChecklistView(
                    checklist: Binding(
                        get: { checklists[index.id] },
                        set: { updatedChecklist in
                            checklists[index.id] = updatedChecklist
                            persistence.save(checklists)
                        }
                    ),
                    onComplete: { checklist in
                        checklists[index.id] = checklist
                        checklists[index.id].state = .completed
                        checklists[index.id].completionDate = Date()
                        persistence.save(checklists)
                    },
                    onDismiss: { shouldSave in
                        if shouldSave {
                            persistence.save(checklists)
                        } else {
                            checklists.remove(at: index.id)
                            persistence.save(checklists)
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showingSettingsSheet) {
            SettingsView(
                persistence: persistence,
                onDataChange: {
                    loadData()
                }
            )
        }
        .onAppear {
            loadData()
        }
        .environmentObject(shipDetails)
    }
    
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Checklists")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                menuButton
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            .padding(.top, 20)
            .padding(.bottom, 10)
            
            Divider()
                .background(.white.opacity(0.3))
        }
        .background(Color(red: 0.1, green: 0.1, blue: 0.2)) // Dark blue color
    }

    private var checklistsList: some View {
        List {
            templatesSection
            inProgressSection
            historySection
        }
        .listStyle(.plain)
    }

    private var templatesSection: some View {
        Section {
            let templates = checklists.filter { $0.state == .template }
            ForEach(templates) { checklist in
                templateRow(for: checklist)
            }
        } header: {
            Text("Templates")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .textCase(nil)
        }
    }

    private var inProgressSection: some View {
        Section {
            let inProgressIndices = checklists.indices.filter { checklists[$0].state == .inProgress }
            ForEach(inProgressIndices, id: \.self) { index in
                inProgressRow(at: index)
            }
        } header: {
            Text("In Progress")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .textCase(nil)
        }
    }

    private var historySection: some View {
        Section {
            let completedIndices = checklists.indices.filter { checklists[$0].state == .completed }
            if !completedIndices.isEmpty {
                ForEach(completedIndices, id: \.self) { index in
                    completedRow(at: index)
                }
            } else {
                Text("No completed checklists")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            }
        } header: {
            Text("History")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .textCase(nil)
        }
    }

    // MARK: - Helper Methods

    private func templateRow(for checklist: Checklist) -> some View {
        Button {
            // Create new instance that won't be affected by template changes
            let newChecklist = checklist.createInstance()
            
            // Save the new checklist immediately
            var updatedChecklists = checklists
            updatedChecklists.append(newChecklist)
            checklists = updatedChecklists
            persistence.save(checklists)
            
            // Then show it
            if let index = checklists.firstIndex(where: { $0.id == newChecklist.id }) {
                activeChecklistIndex = IdentifiableIndex(index)
            }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(checklist.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if !checklist.subtitle.isEmpty {
                    Text(checklist.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                selectedChecklistForEditing = checklist
            } label: {
                Image(systemName: "pencil")
                    .font(.title2)
            }
            .tint(.blue)
        }
    }

    private func inProgressRow(at index: Int) -> some View {
        Button {
            activeChecklistIndex = IdentifiableIndex(index)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(checklists[index].name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // Location and Purpose details combined
                let locationText = getLocationDetails(checklists[index])
                let purposeText = getPurposeDetails(checklists[index])
                
                if !locationText.isEmpty || !purposeText.isEmpty {
                    Text([locationText, purposeText].filter { !$0.isEmpty }.joined(separator: " • "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if !checklists[index].subtitle.isEmpty {
                    Text(checklists[index].subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("Started: \(formattedDate(checklists[index].createdDate)) • \(calculateCompletionPercentage(checklists[index]))% Complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
    }

    private func completedRow(at index: Int) -> some View {
        Button {
            activeChecklistIndex = IdentifiableIndex(index)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(checklists[index].name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // Location and Purpose details combined
                let locationText = getLocationDetails(checklists[index])
                let purposeText = getPurposeDetails(checklists[index])
                
                if !locationText.isEmpty || !purposeText.isEmpty {
                    Text([locationText, purposeText].filter { !$0.isEmpty }.joined(separator: " • "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if !checklists[index].subtitle.isEmpty {
                    Text(checklists[index].subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("Completed: \(formattedDate(checklists[index].completionDate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
    }

    private func addNewChecklist() {
        guard !newChecklistName.isEmpty else { return }
        let newChecklist = Checklist(name: newChecklistName)
        checklists.append(newChecklist)
        persistence.save(checklists)
        newChecklistName = ""
    }

    private func deleteChecklist(_ checklist: Checklist) {
        if let activeIndex = activeChecklistIndex,
           let checklistIndex = checklists.firstIndex(where: { $0.id == checklist.id }),
           activeIndex.id == checklistIndex {
            activeChecklistIndex = nil
        }
        
        persistence.delete(checklist)
        checklists.removeAll { $0.id == checklist.id }
    }

    private func saveData() {
        if let data = try? JSONEncoder().encode(checklists) {
            UserDefaults.standard.set(data, forKey: "checklists")
            UserDefaults.standard.synchronize()
        }
    }

    private func loadData() {
        checklists.removeAll()
        let loadedChecklists = persistence.load()
        DispatchQueue.main.async {
            // Double check the loaded checklists against deleted items
            self.checklists = loadedChecklists.filter { checklist in
                let prefix = checklist.serialNumber.components(separatedBy: "_").first ?? checklist.serialNumber
                let deletedPrefixes = Set(UserDefaults.standard.stringArray(forKey: "deletedSerialNumberPrefixes") ?? [])
                return !deletedPrefixes.contains(prefix)
            }
        }
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter.string(from: date)
    }

    private func deleteAllData() {
        // Clear UserDefaults
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        
        // Clear persistence
        persistence.deleteAll()
        
        // Clear local state
        checklists = []
        selectedChecklistForEditing = nil
        activeChecklistIndex = nil
        
        // Reload data
        loadData()
    }

    private func importChecklists(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let data = try Data(contentsOf: url)
            let decodedChecklists = try JSONDecoder().decode([Checklist].self, from: data)
            
            let existingSerialNumbers = Set(checklists.map { $0.serialNumber })
            let newChecklists = decodedChecklists.filter { !existingSerialNumbers.contains($0.serialNumber) }
            
            checklists.append(contentsOf: newChecklists)
            persistence.save(checklists)
            
            if decodedChecklists.count != newChecklists.count {
                print("Skipped \(decodedChecklists.count - newChecklists.count) duplicate checklist(s)")
            }
        } catch {
            print("Import failed: \(error.localizedDescription)")
        }
    }

    private var menuButton: some View {
        Menu {
            Button(action: {
                newChecklistName = ""
                isAddingNewChecklist = true
            }) {
                Label("New Template", systemImage: "plus")
            }
            
            Button(action: { showingSettingsSheet = true }) {
                Label("Settings", systemImage: "gear")
            }
            
            Button(action: { showingExportSheet = true }) {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            
            Button(action: { showingImportSheet = true }) {
                Label("Import", systemImage: "square.and.arrow.down")
            }
            
            Button(role: .destructive, action: {
                showingDeleteAllConfirmation = true
            }) {
                Label("Delete All Data", systemImage: "trash")
            }
        } label: {
            Image(systemName: "line.3.horizontal")
                .font(.title2)
                .foregroundColor(.white)
        }
    }

    private func calculateCompletionPercentage(_ checklist: Checklist) -> Int {
        // Filter items that require input
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
        
        // If no items require input, return 100%
        guard !itemsRequiringInput.isEmpty else { return 100 }
        
        // Count completed items
        let completedItems = itemsRequiringInput.filter { item in
            switch item.type {
            case .singleLineCheck, .doubleLineCheck:
                return item.selectedOption != nil
            case .locationDetails, .purposeDetails:
                return item.userInput?.text?.isEmpty == false
            default:
                return true
            }
        }
        
        // Calculate percentage
        return Int((Double(completedItems.count) / Double(itemsRequiringInput.count)) * 100)
    }

    // Add helper functions to get Location and Purpose details
    private func getLocationDetails(_ checklist: Checklist) -> String {
        return checklist.items.first { item in
            item.type == .locationDetails
        }?.userInput?.text ?? ""
    }

    private func getPurposeDetails(_ checklist: Checklist) -> String {
        return checklist.items.first { item in
            item.type == .purposeDetails
        }?.userInput?.text ?? ""
    }
}

// Add this struct to support file export
struct ChecklistDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    var checklists: [Checklist]
    
    init(checklists: [Checklist]) {
        self.checklists = checklists
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let decodedChecklists = try? JSONDecoder().decode([Checklist].self, from: data)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.checklists = decodedChecklists
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder().encode(checklists)
        return .init(regularFileWithContents: data)
    }
}
