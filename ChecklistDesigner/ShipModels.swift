import Foundation
import SwiftUI

// MARK: - Models
struct Tag: Identifiable, Codable, Equatable {
    let id: UUID
    let serialNumber: String
    let text: String
    let createdAt: Date
    
    init(text: String) {
        self.id = UUID()
        self.serialNumber = Tag.generateSerialNumber()
        self.text = text
        self.createdAt = Date()
    }
    
    static func generateSerialNumber() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map { _ in characters.randomElement()! })
    }
}

struct ShipParticulars: Codable {
    var shipName: String = ""
    var imoNumber: String = ""
    var callSign: String = ""
    var flag: String = ""
    var shipType: String = ""
    var isLocked: Bool = false
}

struct AreasAndSpaces: Codable {
    var deckAreas: [Tag] = []
    var engineSpaces: [Tag] = []
    var enclosedSpaces: [Tag] = []
    var isLocked: Bool = false
}

struct CrewPosition: Identifiable, Codable {
    let id: UUID
    var position: String
    
    init(id: UUID = UUID(), position: String) {
        self.id = id
        self.position = position
    }
}

// MARK: - Enums
enum TagSection {
    case deck
    case engine
    case enclosed
}

// MARK: - Manager
@MainActor
class ShipDetailsManager: ObservableObject {
    @Published var areasAndSpaces: AreasAndSpaces {
        didSet {
            saveAreasAndSpaces()
            print("AreasAndSpaces changed")
        }
    }
    
    @Published var shipParticulars: ShipParticulars
    @Published private(set) var crewPositions: [CrewPosition]
    
    private let areasAndSpacesKey = "areasAndSpaces"
    private let shipParticularsKey = "shipParticulars"
    private let crewKey = "crewPositions"
    
    init() {
        self.areasAndSpaces = AreasAndSpaces()
        self.shipParticulars = ShipParticulars()
        self.crewPositions = []
        
        loadData()
    }
    
    private func loadData() {
        do {
            if let data = UserDefaults.standard.data(forKey: areasAndSpacesKey) {
                let savedAreasAndSpaces = try JSONDecoder().decode(AreasAndSpaces.self, from: data)
                self.areasAndSpaces = savedAreasAndSpaces
                print("Successfully loaded areas and spaces")
            }
        } catch {
            print("Error loading areas and spaces: \(error)")
            self.areasAndSpaces = AreasAndSpaces()  // Use default if loading fails
        }
        
        if let data = UserDefaults.standard.data(forKey: shipParticularsKey),
           let savedParticulars = try? JSONDecoder().decode(ShipParticulars.self, from: data) {
            self.shipParticulars = savedParticulars
        }
        
        if let data = UserDefaults.standard.data(forKey: crewKey),
           let loadedCrew = try? JSONDecoder().decode([CrewPosition].self, from: data) {
            self.crewPositions = loadedCrew
        }
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(areasAndSpaces) {
            UserDefaults.standard.set(encoded, forKey: areasAndSpacesKey)
            UserDefaults.standard.synchronize()
            print("Saved areas and spaces with \(areasAndSpaces.deckAreas.count) deck areas, \(areasAndSpaces.engineSpaces.count) engine spaces, and \(areasAndSpaces.enclosedSpaces.count) enclosed spaces")
        }
        
        if let encoded = try? JSONEncoder().encode(shipParticulars) {
            UserDefaults.standard.set(encoded, forKey: shipParticularsKey)
        }
        
        if let encoded = try? JSONEncoder().encode(crewPositions) {
            UserDefaults.standard.set(encoded, forKey: crewKey)
        }
    }
    
    func addTag(text: String, to section: TagSection) {
        let newTag = Tag(text: text)
        print("Creating new tag: \(newTag.text) at \(newTag.createdAt)")
        
        updateAreasAndSpaces { spaces in
            switch section {
            case .deck:
                guard !spaces.deckAreas.contains(where: { $0.text == text }) else { return }
                spaces.deckAreas.append(newTag)
            case .engine:
                guard !spaces.engineSpaces.contains(where: { $0.text == text }) else { return }
                spaces.engineSpaces.append(newTag)
            case .enclosed:
                guard !spaces.enclosedSpaces.contains(where: { $0.text == text }) else { return }
                spaces.enclosedSpaces.append(newTag)
            }
        }
    }
    
    func updateAreasAndSpaces(_ update: (inout AreasAndSpaces) -> Void) {
        var copy = areasAndSpaces
        update(&copy)
        areasAndSpaces = copy
    }
    
    private func saveAreasAndSpaces() {
        if let data = try? JSONEncoder().encode(areasAndSpaces) {
            UserDefaults.standard.set(data, forKey: areasAndSpacesKey)
            UserDefaults.standard.synchronize()
            print("Successfully saved areas and spaces")
        }
    }
    
    func backupTags() {
        let backup = areasAndSpaces
        if let encoded = try? JSONEncoder().encode(backup) {
            UserDefaults.standard.set(encoded, forKey: "areasAndSpaces_backup")
            print("Tags backed up successfully")
        }
    }
    
    func restoreTags() {
        if let data = UserDefaults.standard.data(forKey: "areasAndSpaces_backup"),
           let backup = try? JSONDecoder().decode(AreasAndSpaces.self, from: data) {
            areasAndSpaces = backup
            print("Tags restored successfully")
        }
    }
    
    func addCrewPosition(_ position: String) {
        var updatedPositions = crewPositions
        updatedPositions.append(CrewPosition(position: position))
        crewPositions = updatedPositions
        save()
    }
    
    func removeCrewPosition(at indexSet: IndexSet) {
        var updatedPositions = crewPositions
        updatedPositions.remove(atOffsets: indexSet)
        crewPositions = updatedPositions
        save()
    }
    
    func updateParticulars(_ update: (inout ShipParticulars) -> Void) {
        var copy = shipParticulars
        update(&copy)
        shipParticulars = copy
        save()
    }
    
    func toggleParticularsLock() {
        updateParticulars { particulars in
            particulars.isLocked.toggle()
        }
    }
}

// Add at the end of the file
struct TagView: View {
    let text: String
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: true, vertical: false)
                .lineLimit(1)
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.15))
        .cornerRadius(16)
    }
} 