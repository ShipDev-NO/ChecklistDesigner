//
//  Helpers.swift
//  ChecklistDesigner
//
//  Created by Frode Hjønnevåg on 28/11/2024.
//

import Foundation

func saveData(_ checklists: [Checklist]) {
    if let data = try? JSONEncoder().encode(checklists) {
        UserDefaults.standard.set(data, forKey: "checklists")
    }
}

func loadData() -> [Checklist] {
    if let data = UserDefaults.standard.data(forKey: "checklists"),
       let loadedChecklists = try? JSONDecoder().decode([Checklist].self, from: data) {
        return loadedChecklists
    }
    return []
}

func formattedDate(_ date: Date?) -> String {
    guard let date = date else { return "" }
    let formatter = DateFormatter()
    formatter.dateFormat = "dd.MM.yyyy HH:mm"
    return formatter.string(from: date)
}
import Foundation

// Generate a unique serial number
func generateSerialNumber() -> String {
    let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0..<9).map { _ in characters.randomElement()! })
}
