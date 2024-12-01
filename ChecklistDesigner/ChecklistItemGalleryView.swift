import SwiftUI
import Foundation

struct GalleryItem: Identifiable {
    let id = UUID()
    let type: ChecklistItemType
    let title: String
    let description: String
    let icon: String
}

struct ChecklistItemGalleryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    let onSelect: (ChecklistItemType) -> Void
    
    private let items = [
        GalleryItem(
            type: .descriptionText,
            title: "Description Text",
            description: "Add formatted text for detailed descriptions",
            icon: "text.justify"
        ),
        GalleryItem(
            type: .locationDetails,
            title: "Location Details",
            description: "Add location information with user input",
            icon: "location"
        ),
        GalleryItem(
            type: .purposeDetails,
            title: "Purpose Details",
            description: "Add purpose with user input",
            icon: "questionmark.circle"
        ),
        GalleryItem(
            type: .validityDetails,
            title: "Validity Details",
            description: "Add valid date range for the item",
            icon: "calendar"
        ),
        GalleryItem(
            type: .paragraphHeader,
            title: "Paragraph Header",
            description: "Add section header with optional subtext",
            icon: "text.header"
        ),
        GalleryItem(
            type: .singleLineCheck,
            title: "Single Line Check",
            description: "Add checkbox item with one line of text",
            icon: "checkmark.square"
        ),
        GalleryItem(
            type: .doubleLineCheck,
            title: "Double Line Check",
            description: "Add checkbox item with additional support text",
            icon: "checkmark.square.fill"
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 0) {
                HStack {
                    Text("Add Item")
                        .viewTitleStyle()
                    Spacer()
                    Button("Cancel") {
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
            
            // List of items
            List {
                Section {
                    ForEach(items) { item in
                        Button(action: { onSelect(item.type) }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(item.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                } header: {
                    Text("Available Items")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .textCase(nil)
                }
            }
            .listStyle(.plain)
        }
        .background(themeManager.backgroundColor)
    }
} 