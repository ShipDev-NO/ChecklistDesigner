//
//  ChecklistPersistence.swift
//

import Foundation

class ChecklistPersistence: ObservableObject {
    @Published private(set) var checklists: [Checklist] = []
    private let saveKey = "savedChecklists"
    private let deletedIDsKey = "deletedChecklistIDs"
    
    init() {
        checklists = load()
    }
    
    func load() -> [Checklist] {
        print("ChecklistPersistence - load called")
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Checklist].self, from: data) {
            // Filter out deleted checklists
            let filtered = decoded.filter { checklist in
                !loadDeletedIDs().contains(checklist.id.uuidString) &&
                !loadDeletedIDs().contains(checklist.serialNumber)
            }
            print("ChecklistPersistence - Loaded \(filtered.count) checklists")
            print("ChecklistPersistence - Templates count: \(filtered.filter { $0.state == .template }.count)")
            
            // Debug print all templates
            filtered.filter { $0.state == .template }.forEach { template in
                print("Template: \(template.name) - Items: \(template.items.count)")
            }
            
            checklists = filtered
            return filtered
        }
        print("ChecklistPersistence - No checklists found")
        return []
    }
    
    func save(_ checklists: [Checklist]) {
        print("\n=== PERSISTENCE SAVE ===")
        print("Saving \(checklists.count) checklists")
        print("Including \(checklists.filter { $0.state == .template }.count) templates")
        
        if let encoded = try? JSONEncoder().encode(checklists) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
            UserDefaults.standard.synchronize()
            self.checklists = checklists
            print("Save to UserDefaults completed")
            
            if let data = UserDefaults.standard.data(forKey: saveKey),
               let decoded = try? JSONDecoder().decode([Checklist].self, from: data) {
                print("Verification read successful")
                print("Verified \(decoded.count) checklists")
                print("Including \(decoded.filter { $0.state == .template }.count) templates")
                decoded.filter { $0.state == .template }.forEach { template in
                    print("Template: \(template.name)")
                }
            }
        }
        print("=== PERSISTENCE SAVE COMPLETE ===\n")
    }
    
    func delete(_ checklist: Checklist) {
        var deletedIDs = loadDeletedIDs()
        
        // Add the checklist ID to permanently deleted list
        deletedIDs.insert(checklist.id.uuidString)
        deletedIDs.insert(checklist.serialNumber)
        
        // If it's a template, also mark its serial number pattern for deletion
        if checklist.state == .template {
            let pattern = "\(checklist.id.uuidString)_"
            let relatedChecklists = checklists.filter { $0.serialNumber.hasPrefix(pattern) }
            for related in relatedChecklists {
                deletedIDs.insert(related.id.uuidString)
                deletedIDs.insert(related.serialNumber)
            }
        }
        
        // Save updated deleted IDs
        saveDeletedIDs(deletedIDs)
        
        // Remove from current checklists and save
        var updatedChecklists = checklists
        updatedChecklists.removeAll { $0.id == checklist.id }
        save(updatedChecklists)
    }
    
    func deleteAll() {
        UserDefaults.standard.removeObject(forKey: saveKey)
        UserDefaults.standard.removeObject(forKey: deletedIDsKey)
        checklists = []
    }
    
    // MARK: - Private Helper Methods
    
    private func loadDeletedIDs() -> Set<String> {
        if let data = UserDefaults.standard.data(forKey: deletedIDsKey),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            return decoded
        }
        return []
    }
    
    private func saveDeletedIDs(_ deletedIDs: Set<String>) {
        if let encoded = try? JSONEncoder().encode(deletedIDs) {
            UserDefaults.standard.set(encoded, forKey: deletedIDsKey)
        }
    }
}
