import SwiftUI

struct AreasAndSpacesView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var shipDetails: ShipDetailsManager
    @State private var newDeckArea = ""
    @State private var newEngineSpace = ""
    @State private var newEnclosedSpace = ""
    @FocusState private var focusedField: Field?
    
    enum Field {
        case deckArea
        case engineSpace
        case enclosedSpace
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 0) {
                HStack {
                    Text("Areas and Spaces")
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
                Section(header: Text("Deck Areas and Spaces")) {
                    tagInputSection(
                        tags: Binding(
                            get: { shipDetails.areasAndSpaces.deckAreas },
                            set: { newValue in
                                shipDetails.updateAreasAndSpaces { spaces in
                                    spaces.deckAreas = newValue
                                }
                            }
                        ),
                        newTag: $newDeckArea,
                        placeholder: "Add space",
                        field: .deckArea,
                        section: .deck
                    )
                }
                
                Section(header: Text("Engine and Accommodation Spaces")) {
                    tagInputSection(
                        tags: Binding(
                            get: { shipDetails.areasAndSpaces.engineSpaces },
                            set: { newValue in
                                shipDetails.updateAreasAndSpaces { spaces in
                                    spaces.engineSpaces = newValue
                                }
                            }
                        ),
                        newTag: $newEngineSpace,
                        placeholder: "Add space",
                        field: .engineSpace,
                        section: .engine
                    )
                }
                
                Section(header: Text("Enclosed Spaces")) {
                    tagInputSection(
                        tags: Binding(
                            get: { shipDetails.areasAndSpaces.enclosedSpaces },
                            set: { newValue in
                                shipDetails.updateAreasAndSpaces { spaces in
                                    spaces.enclosedSpaces = newValue
                                }
                            }
                        ),
                        newTag: $newEnclosedSpace,
                        placeholder: "Add space",
                        field: .enclosedSpace,
                        section: .enclosed
                    )
                }
            }
            .listStyle(.plain)
        }
    }
    
    private func tagInputSection(tags: Binding<[Tag]>, newTag: Binding<String>, placeholder: String, field: Field, section: TagSection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if !shipDetails.areasAndSpaces.isLocked {
                TextField(placeholder, text: newTag)
                    .onSubmit {
                        if !newTag.wrappedValue.isEmpty {
                            shipDetails.addTag(text: newTag.wrappedValue, to: section)
                            newTag.wrappedValue = ""
                            focusedField = field
                        }
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 8)
                    .focused($focusedField, equals: field)
            }
            
            FlowLayout(spacing: 8) {
                ForEach(tags.wrappedValue) { tag in
                    TagView(text: tag.text) {
                        if !shipDetails.areasAndSpaces.isLocked {
                            shipDetails.updateAreasAndSpaces { spaces in
                                switch section {
                                case .deck:
                                    spaces.deckAreas.removeAll { $0.id == tag.id }
                                case .engine:
                                    spaces.engineSpaces.removeAll { $0.id == tag.id }
                                case .enclosed:
                                    spaces.enclosedSpaces.removeAll { $0.id == tag.id }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct CrewPositionsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var shipDetails: ShipDetailsManager
    @State private var newPosition = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 0) {
                HStack {
                    Text("Crew Positions")
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
                    TextField("Add Position", text: $newPosition)
                        .onSubmit {
                            if !newPosition.isEmpty {
                                shipDetails.addCrewPosition(newPosition)
                                newPosition = ""
                            }
                        }
                }
                
                Section {
                    ForEach(shipDetails.crewPositions) { position in
                        Text(position.position)
                    }
                    .onDelete { indexSet in
                        shipDetails.removeCrewPosition(at: indexSet)
                    }
                }
            }
            .listStyle(.plain)
        }
    }
} 