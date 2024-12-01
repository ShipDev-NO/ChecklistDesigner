//
//  SettingsView.swift
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var shipDetails: ShipDetailsManager
    let persistence: ChecklistPersistence
    let onDataChange: () -> Void
    @State private var showingDeleteConfirmation = false
    @State private var showingBackupConfirmation = false
    @State private var showingRestoreConfirmation = false
    @State private var showingDocumentPicker = false
    @State private var documentPickerMode: DocumentPickerMode = .import
    @State private var documentType: DocumentType = .templates
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 0) {
                    HStack {
                        Text("Settings")
                            .viewTitleStyle()
                        Spacer()
                        Button("Done") {
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
                    Section {
                        Toggle(isOn: $themeManager.isDarkMode) {
                            Label("Dark Mode", systemImage: themeManager.isDarkMode ? "moon.fill" : "moon")
                                .settingsLabelStyle()
                        }
                    } header: {
                        Text("Appearance")
                            .textCase(nil)
                            .foregroundColor(.secondary)
                            .font(.body)
                    }
                    
                    Section {
                        NavigationLink {
                            ShipParticularsView(shipDetails: shipDetails)
                        } label: {
                            Label("Ship Particulars", systemImage: "sailboat")
                                .settingsLabelStyle()
                        }
                        
                        NavigationLink {
                            AreasAndSpacesView(shipDetails: shipDetails)
                        } label: {
                            Label("Areas and Spaces", systemImage: "square.grid.2x2")
                                .settingsLabelStyle()
                        }
                        
                        NavigationLink {
                            CrewPositionsView(shipDetails: shipDetails)
                        } label: {
                            Label("Crew", systemImage: "person.2")
                                .settingsLabelStyle()
                        }
                    } header: {
                        Text("Ship Details")
                            .textCase(nil)
                            .foregroundColor(.secondary)
                            .font(.body)
                    }
                    
                    importExportSection
                    
                    adminToolsSection
                }
                .listStyle(.plain)
            }
            .alert("Delete All Data?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    persistence.deleteAll()
                    onDataChange()
                }
            }
            .alert("Backup Tags?", isPresented: $showingBackupConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Backup", role: .none) {
                    shipDetails.backupTags()
                }
            }
            .alert("Restore Tags?", isPresented: $showingRestoreConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Restore", role: .destructive) {
                    shipDetails.restoreTags()
                }
            }
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPicker(
                    mode: documentPickerMode,
                    documentType: documentType,
                    onExport: { url in
                        do {
                            switch documentType {
                            case .templates:
                                try exportTemplates(to: url)
                            case .checklists:
                                try exportChecklists(to: url)
                            case .tags:
                                try exportTags(to: url)
                            }
                        } catch {
                            print("Error exporting: \(error)")
                        }
                    },
                    onImport: { url in
                        switch documentType {
                        case .templates:
                            importTemplates(from: url)
                        case .checklists:
                            importChecklists(from: url)
                        case .tags:
                            importTags(from: url)
                        }
                    }
                )
            }
        }
    }
    
    private var adminToolsSection: some View {
        Section {
            Button(action: {
                showingDeleteConfirmation = true
            }) {
                Label("Delete All Data", systemImage: "trash")
                    .foregroundColor(.red)
            }
            
            Button(action: {
                showingBackupConfirmation = true
            }) {
                Label("Backup Tags", systemImage: "square.and.arrow.down")
                    .settingsLabelStyle()
            }
            
            Button(action: {
                showingRestoreConfirmation = true
            }) {
                Label("Restore Tags", systemImage: "square.and.arrow.up")
                    .settingsLabelStyle()
            }
        } header: {
            Text("Admin Tools")
                .textCase(nil)
                .foregroundColor(.secondary)
                .font(.body)
        }
    }
    
    private var importExportSection: some View {
        Section {
            // Templates
            Button(action: { 
                documentType = .templates
                documentPickerMode = .export
                showingDocumentPicker = true
            }) {
                Label("Export Templates", systemImage: "square.and.arrow.up")
                    .settingsLabelStyle()
            }
            
            Button(action: { 
                documentType = .templates
                documentPickerMode = .import
                showingDocumentPicker = true
            }) {
                Label("Import Templates", systemImage: "square.and.arrow.down")
                    .settingsLabelStyle()
            }
            
            // In Progress & History
            Button(action: { 
                documentType = .checklists
                documentPickerMode = .export
                showingDocumentPicker = true
            }) {
                Label("Export In Progress & History", systemImage: "square.and.arrow.up")
                    .settingsLabelStyle()
            }
            
            Button(action: { 
                documentType = .checklists
                documentPickerMode = .import
                showingDocumentPicker = true
            }) {
                Label("Import In Progress & History", systemImage: "square.and.arrow.down")
                    .settingsLabelStyle()
            }
            
            // Tags
            Button(action: { 
                documentType = .tags
                documentPickerMode = .export
                showingDocumentPicker = true
            }) {
                Label("Export Tags", systemImage: "square.and.arrow.up")
                    .settingsLabelStyle()
            }
            
            Button(action: { 
                documentType = .tags
                documentPickerMode = .import
                showingDocumentPicker = true
            }) {
                Label("Import Tags", systemImage: "square.and.arrow.down")
                    .settingsLabelStyle()
            }
        } header: {
            Text("Import/Export")
                .textCase(nil)
                .foregroundColor(.secondary)
                .font(.body)
        }
    }
    
    private func exportTemplates(to url: URL) throws {
        let templates = persistence.load().filter { $0.state == .template }
        let data = try JSONEncoder().encode(templates)
        try data.write(to: url)
    }
    
    private func importTemplates(from url: URL) {
        do {
            guard url.startAccessingSecurityScopedResource() else {
                throw NSError(domain: "Import", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to access file"])
            }
            defer { url.stopAccessingSecurityScopedResource() }
            
            let data = try Data(contentsOf: url)
            let templates = try JSONDecoder().decode([Checklist].self, from: data)
            
            var checklists = persistence.load()
            checklists.removeAll { checklist in
                templates.contains { $0.id == checklist.id }
            }
            checklists.append(contentsOf: templates)
            persistence.save(checklists)
            
            DispatchQueue.main.async {
                onDataChange()
                dismiss()
            }
            
            print("Successfully imported \(templates.count) templates")
        } catch {
            print("Error importing templates: \(error)")
        }
    }
    
    private func exportChecklists(to url: URL) throws {
        let checklists = persistence.load().filter { $0.state != .template }
        let data = try JSONEncoder().encode(checklists)
        try data.write(to: url)
    }
    
    private func importChecklists(from url: URL) {
        do {
            guard url.startAccessingSecurityScopedResource() else {
                throw NSError(domain: "Import", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to access file"])
            }
            defer { url.stopAccessingSecurityScopedResource() }
            
            let data = try Data(contentsOf: url)
            let importedChecklists = try JSONDecoder().decode([Checklist].self, from: data)
            
            var checklists = persistence.load()
            checklists.removeAll { checklist in
                importedChecklists.contains { $0.id == checklist.id }
            }
            checklists.append(contentsOf: importedChecklists)
            persistence.save(checklists)
            
            DispatchQueue.main.async {
                onDataChange()
                dismiss()
            }
        } catch {
            print("Error importing checklists: \(error)")
        }
    }
    
    private func exportTags(to url: URL) throws {
        let data = try JSONEncoder().encode(shipDetails.areasAndSpaces)
        try data.write(to: url)
        print("Successfully exported tags")
    }
    
    private func importTags(from url: URL) {
        do {
            guard url.startAccessingSecurityScopedResource() else {
                throw NSError(domain: "Import", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to access file"])
            }
            defer { url.stopAccessingSecurityScopedResource() }
            
            let data = try Data(contentsOf: url)
            let areasAndSpaces = try JSONDecoder().decode(AreasAndSpaces.self, from: data)
            
            DispatchQueue.main.async {
                shipDetails.updateAreasAndSpaces { $0 = areasAndSpaces }
                dismiss()
            }
            
            print("Successfully imported tags")
        } catch {
            print("Error importing tags: \(error)")
        }
    }
}

extension Label where Title == Text, Icon == Image {
    func settingsLabelStyle() -> some View {
        self.foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.2))
    }
}

// Define the document types
enum DocumentType {
    case templates
    case checklists
    case tags
}

enum DocumentPickerMode {
    case `import`
    case export
} 