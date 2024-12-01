//
//  ChecklistModels.swift
//  ChecklistDesigner
//
//  Created by Frode Hjønnevåg on 27/11/2024.
//

import Foundation

// Checklist Item Type
enum ChecklistItemType: String, Codable {
    case descriptionText
    case locationDetails
    case purposeDetails
    case validityDetails
    case paragraphHeader
    case singleLineCheck
    case doubleLineCheck
}

// Checklist State
enum ChecklistState: String, Codable {
    case template      // Checklist is a reusable template
    case inProgress    // Checklist is actively being filled out
    case completed     // Checklist has been completed
}

// Checklist Item Model
struct ChecklistItem: Identifiable, Codable, Equatable {
    let id: UUID
    var type: ChecklistItemType
    var headerText: String
    var bodyText: String
    var supportText: String?
    var userInput: ChecklistItemUserInput?
    var checkOptions: CheckOptions?
    var formatting: TextFormatting?
    var selectedOption: String?
    var validityStartDate: Date?
    var validityDurationHours: Int?
    var validityEndDate: Date? {
        guard let startDate = validityStartDate,
              let hours = validityDurationHours else { return nil }
        return Calendar.current.date(byAdding: .hour, value: hours, to: startDate)
    }
    var maxValidityHours: Int?
    var locationSettings: LocationSettings?

    init(
        id: UUID = UUID(),
        type: ChecklistItemType = .descriptionText,
        headerText: String = "",
        bodyText: String = "",
        supportText: String? = nil,
        userInput: ChecklistItemUserInput? = nil,
        checkOptions: CheckOptions? = nil,
        formatting: TextFormatting? = nil,
        selectedOption: String? = nil,
        validityStartDate: Date? = nil,
        validityDurationHours: Int? = nil,
        maxValidityHours: Int? = nil,
        locationSettings: LocationSettings? = nil
    ) {
        self.id = id
        self.type = type
        self.headerText = headerText
        self.bodyText = bodyText
        self.supportText = supportText
        self.userInput = userInput
        self.checkOptions = checkOptions
        self.formatting = formatting
        self.selectedOption = selectedOption
        self.validityStartDate = validityStartDate
        self.validityDurationHours = validityDurationHours
        self.maxValidityHours = maxValidityHours
        self.locationSettings = locationSettings
        
        // Initialize locationSettings if this is a location details item
        if type == .locationDetails && locationSettings == nil {
            self.locationSettings = LocationSettings()
        }
    }

    // Swift automatically synthesizes Equatable if all stored properties conform to Equatable.
}


// Check Options Model
struct CheckOptions: Codable, Equatable {
    var yes: Bool
    var no: Bool
    var na: Bool
    
    init(yes: Bool = true, no: Bool = true, na: Bool = true) {
        self.yes = yes
        self.no = no
        self.na = na
    }
}


// Checklist Model
struct Checklist: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var subtitle: String
    var revisionNumber: Int
    var revisionDate: Date
    var approvedBy: String
    var items: [ChecklistItem]
    var serialNumber: String
    var state: ChecklistState
    var createdDate: Date?
    var completionDate: Date?

    init(
        id: UUID = UUID(),
        name: String,
        subtitle: String = "",
        revisionNumber: Int = 1,
        revisionDate: Date = Date(),
        approvedBy: String = "",
        items: [ChecklistItem] = [],
        state: ChecklistState = .template,
        createdDate: Date? = nil,
        completionDate: Date? = nil,
        serialNumber: String? = nil
    ) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.revisionNumber = revisionNumber
        self.revisionDate = revisionDate
        self.approvedBy = approvedBy
        self.items = items
        self.state = state
        self.createdDate = createdDate
        self.completionDate = completionDate
        self.serialNumber = serialNumber ?? (state == .template ? Checklist.generateSerialNumber() : "")
    }

    // Create a new "In Progress" instance from a template
    func createInstance() -> Checklist {
        let instanceItems = items.map { templateItem in
            ChecklistItem(
                id: UUID(),
                type: templateItem.type,
                headerText: templateItem.headerText,
                bodyText: templateItem.bodyText,
                supportText: templateItem.supportText,
                userInput: nil,
                checkOptions: templateItem.checkOptions?.copy(),
                formatting: templateItem.formatting?.copy(),
                selectedOption: nil,
                validityStartDate: templateItem.type == .validityDetails ? Date() : nil,
                validityDurationHours: templateItem.type == .validityDetails ? templateItem.validityDurationHours : nil,
                maxValidityHours: templateItem.maxValidityHours,
                locationSettings: templateItem.locationSettings?.copy()
            )
        }
        
        return Checklist(
            id: UUID(),
            name: name,
            subtitle: subtitle,
            revisionNumber: revisionNumber,
            revisionDate: revisionDate,
            approvedBy: approvedBy,
            items: instanceItems,
            state: .inProgress,
            createdDate: Date(),
            completionDate: nil,
            serialNumber: "\(self.id.uuidString)_\(Date().timeIntervalSince1970)"
        )
    }

    // Static Serial Number Generator
    static func generateSerialNumber() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<10).map { _ in characters.randomElement()! })
    }

    // Add Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Checklist, rhs: Checklist) -> Bool {
        lhs.id == rhs.id
    }
}

// User input types
struct ChecklistItemUserInput: Codable, Equatable {
    var text: String?
    var startDate: Date?
    var endDate: Date?
}

// Text formatting options
struct TextFormatting: Codable, Equatable {
    var isBold: Bool = false
    var alignment: TextAlignment = .left
}

enum TextAlignment: String, Codable {
    case left
    case center
    case justified
}

// Add copy methods for supporting types
extension CheckOptions {
    func copy() -> CheckOptions {
        CheckOptions(yes: yes, no: no, na: na)
    }
}

extension TextFormatting {
    func copy() -> TextFormatting {
        TextFormatting(isBold: isBold, alignment: alignment)
    }
}

struct LocationSettings: Codable, Equatable {
    var description: String = ""
    var allowDeckAreas: Bool = true
    var allowEngineSpaces: Bool = true
    var allowEnclosedSpaces: Bool = true
    var maxLocations: Int = 1  // Default to single location
    
    func copy() -> LocationSettings {
        LocationSettings(
            description: description,
            allowDeckAreas: allowDeckAreas,
            allowEngineSpaces: allowEngineSpaces,
            allowEnclosedSpaces: allowEnclosedSpaces,
            maxLocations: maxLocations
        )
    }
}

