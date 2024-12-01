import Foundation

protocol TemplateManaging {
    func saveTemplate(_ template: Checklist)
    func loadTemplate(withId id: UUID) -> Checklist?
    func deleteTemplate(_ template: Checklist)
}

class TemplateManager: TemplateManaging {
    private let persistence: ChecklistPersistence
    
    init(persistence: ChecklistPersistence) {
        self.persistence = persistence
    }
    
    func saveTemplate(_ template: Checklist) {
        print("\n=== TEMPLATE MANAGER SAVE ===")
        print("Saving template: \(template.name)")
        
        let allChecklists = persistence.load()
        print("Current checklists: \(allChecklists.count)")
        print("Current templates: \(allChecklists.filter { $0.state == .template }.map { $0.name })")
        
        // Remove old version of this template
        var updatedChecklists = allChecklists.filter { $0.id != template.id }
        
        // Add new version
        updatedChecklists.append(template)
        
        print("\nAfter update:")
        print("Updated templates: \(updatedChecklists.filter { $0.state == .template }.map { $0.name })")
        
        persistence.save(updatedChecklists)
        print("=== TEMPLATE MANAGER SAVE COMPLETE ===\n")
    }
    
    func loadTemplate(withId id: UUID) -> Checklist? {
        let allChecklists = persistence.load()
        return allChecklists.first(where: { $0.id == id })
    }
    
    func deleteTemplate(_ template: Checklist) {
        persistence.delete(template)
    }
} 