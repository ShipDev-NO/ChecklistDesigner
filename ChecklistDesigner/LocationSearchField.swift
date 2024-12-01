import SwiftUI

struct LocationSearchField: View {
    @EnvironmentObject private var shipDetails: ShipDetailsManager
    @Binding var searchText: String
    @Binding var selectedTags: [Tag]
    let settings: LocationSettings
    let isLocked: Bool
    let onShowAreasAndSpaces: (String) -> Void
    
    @State private var showingSuggestions = false
    @State private var showingNotFoundAlert = false
    @State private var filteredTags: [Tag] = []
    @State private var pendingSearchText: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search locations...", text: $searchText)
                    .textFieldStyle(.plain)
                    .disabled(isLocked)
                    .onChange(of: searchText) { _, newValue in
                        Task { @MainActor in
                            await updateSuggestions(for: newValue)
                        }
                    }
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            // Selected tags
            FlowLayout(spacing: 8) {
                ForEach(selectedTags) { tag in
                    TagView(text: tag.text) {
                        if !isLocked {
                            withAnimation {
                                selectedTags.removeAll { $0.id == tag.id }
                            }
                        }
                    }
                }
            }
            
            // Suggestions
            if showingSuggestions && !searchText.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(filteredTags) { tag in
                            Button {
                                selectTag(tag)
                            } label: {
                                Text(tag.text)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: 200)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
        }
        .alert("Location Not Found", isPresented: $showingNotFoundAlert) {
            Button("Cancel", role: .cancel) {
                searchText = ""
            }
            Button("Add Location") {
                onShowAreasAndSpaces(pendingSearchText)
                searchText = ""
            }
        } message: {
            Text("'\(pendingSearchText)' is not defined in the ship's areas and spaces. Would you like to add it?")
        }
    }
    
    @MainActor
    private func updateSuggestions(for searchText: String) async {
        guard !searchText.isEmpty else {
            showingSuggestions = false
            filteredTags = []
            return
        }
        
        // Get allowed tags based on settings
        var allowedTags: [Tag] = []
        if settings.allowDeckAreas {
            allowedTags += shipDetails.areasAndSpaces.deckAreas
        }
        if settings.allowEngineSpaces {
            allowedTags += shipDetails.areasAndSpaces.engineSpaces
        }
        if settings.allowEnclosedSpaces {
            allowedTags += shipDetails.areasAndSpaces.enclosedSpaces
        }
        
        // Filter tags
        filteredTags = allowedTags.filter { tag in
            tag.text.localizedCaseInsensitiveContains(searchText)
        }
        
        if filteredTags.isEmpty {
            pendingSearchText = searchText
            showingNotFoundAlert = true
            showingSuggestions = false
        } else {
            showingSuggestions = true
        }
    }
    
    private func selectTag(_ tag: Tag) {
        guard selectedTags.count < settings.maxLocations else { return }
        guard !selectedTags.contains(where: { $0.id == tag.id }) else { return }
        
        withAnimation {
            selectedTags.append(tag)
            searchText = ""
            showingSuggestions = false
        }
    }
} 