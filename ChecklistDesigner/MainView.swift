import SwiftUI

struct MainView: View {
    @StateObject private var persistence = ChecklistPersistence()
    private let templateManager: TemplateManaging
    
    @State private var selectedTemplate: Checklist?
    @State private var templates: [Checklist] = []
    @State private var inProgressChecklists: [Checklist] = []
    @State private var completedChecklists: [Checklist] = []
    
    @State private var showingNewChecklist = false
    @State private var showingTemplateEditor = false
    
    init() {
        let persistence = ChecklistPersistence()
        self.templateManager = TemplateManager(persistence: persistence)
        self._persistence = StateObject(wrappedValue: persistence)
    }
    
    private var templateEditorSheet: some View {
        Group {
            if let template = selectedTemplate {
                NavigationStack {
                    ChecklistEditorView(
                        checklist: Binding(
                            get: { template },
                            set: { updatedTemplate in
                                print("\n=== MAIN VIEW BINDING SET ===")
                                print("Updating template from: \(template.name) to: \(updatedTemplate.name)")
                                
                                // Update the template in the templates array
                                if let index = templates.firstIndex(where: { $0.id == template.id }) {
                                    // Update templates array
                                    templates[index] = updatedTemplate
                                    
                                    // Update selected template
                                    selectedTemplate = updatedTemplate
                                    
                                    // Save all checklists
                                    let allChecklists = templates + inProgressChecklists + completedChecklists
                                    persistence.save(allChecklists)
                                    
                                    // Force UI update
                                    loadChecklists()
                                    
                                    print("Template updated and saved: \(updatedTemplate.name)")
                                }
                            }
                        ),
                        onSave: {
                            print("\n=== MAIN VIEW ON SAVE ===")
                            showingTemplateEditor = false
                            print("Template editor closed")
                        }
                    )
                    .interactiveDismissDisabled()
                }
            }
        }
    }
    
    private func loadChecklists() {
        print("MainView - Loading checklists...")
        let allChecklists = persistence.load()
        
        templates = allChecklists.filter { $0.state == .template }
        print("MainView - Loaded \(templates.count) templates")
        
        inProgressChecklists = allChecklists.filter { $0.state == .inProgress }
        completedChecklists = allChecklists.filter { $0.state == .completed }
    }
    
    var body: some View {
        NavigationStack {
            mainList
                .navigationTitle("Checklists")
                .sheet(isPresented: $showingNewChecklist) {
                    newChecklistSheet
                }
                .sheet(isPresented: $showingTemplateEditor) {
                    templateEditorSheet
                }
                .onAppear {
                    loadChecklists()
                }
        }
    }
    
    private var mainList: some View {
        List {
            // Templates section
            templatesSection
            
            // In Progress section
            inProgressSection
            
            // History section
            historySection
        }
    }
    
    private var templatesSection: some View {
        Section(header: Text("Templates")) {
            ForEach(templates) { template in
                templateRow(template)
            }
        }
    }
    
    private func templateRow(_ template: Checklist) -> some View {
        HStack {
            Text(template.name)
                .font(.headline)
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedTemplate = template
            showingNewChecklist = true
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                selectedTemplate = template
                showingTemplateEditor = true
            } label: {
                Image(systemName: "pencil")
                    .font(.title2)
            }
            .tint(.blue)
        }
    }
    
    private var inProgressSection: some View {
        Section(header: Text("In Progress")) {
            ForEach(inProgressChecklists) { checklist in
                NavigationLink {
                    UseChecklistView(
                        checklist: binding(for: checklist),
                        onComplete: { completedChecklist in
                            updateChecklist(completedChecklist)
                        },
                        onDismiss: { shouldSave in
                            if shouldSave {
                                loadChecklists()
                            }
                        }
                    )
                } label: {
                    Text(checklist.name)
                }
            }
        }
    }
    
    private var historySection: some View {
        Section(header: Text("History")) {
            ForEach(completedChecklists) { checklist in
                NavigationLink {
                    UseChecklistView(
                        checklist: binding(for: checklist),
                        onComplete: { completedChecklist in
                            updateChecklist(completedChecklist)
                        },
                        onDismiss: { shouldSave in
                            if shouldSave {
                                loadChecklists()
                            }
                        }
                    )
                } label: {
                    Text(checklist.name)
                }
            }
        }
    }
    
    private var newChecklistSheet: some View {
        Group {
            if let template = selectedTemplate {
                NavigationStack {
                    UseChecklistView(
                        checklist: .constant(template.createInstance()),
                        onComplete: { newChecklist in
                            inProgressChecklists.append(newChecklist)
                            persistence.save(templates + inProgressChecklists + completedChecklists)
                        },
                        onDismiss: { shouldSave in
                            if shouldSave {
                                loadChecklists()
                            }
                        }
                    )
                }
            }
        }
    }
    
    private func updateChecklist(_ checklist: Checklist) {
        var allChecklists = templates + inProgressChecklists + completedChecklists
        if let index = allChecklists.firstIndex(where: { $0.id == checklist.id }) {
            allChecklists[index] = checklist
            persistence.save(allChecklists)
            loadChecklists()
        }
    }
    
    private func binding(for checklist: Checklist) -> Binding<Checklist> {
        Binding(
            get: { checklist },
            set: { newValue in
                updateChecklist(newValue)
            }
        )
    }
} 