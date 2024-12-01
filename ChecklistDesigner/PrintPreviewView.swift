import SwiftUI

struct PrintPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    let checklist: Checklist
    
    var body: some View {
        NavigationStack {
            ScrollView {
                printContent
                    .padding()
                    .frame(maxWidth: 595, maxHeight: .infinity) // A4 width in points
            }
            .navigationTitle("Print Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: printChecklist) {
                        Image(systemName: "printer")
                    }
                }
            }
        }
    }
    
    private var printContent: some View {
        VStack(spacing: 20) {
            // Header - centered
            VStack(spacing: 8) {
                Text(checklist.name)
                    .font(.title)
                    .bold()
                    .multilineTextAlignment(.center)
                
                if !checklist.subtitle.isEmpty {
                    Text(checklist.subtitle)
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                HStack(spacing: 16) {
                    Spacer()
                    Text("Rev \(String(format: "%02d", checklist.revisionNumber))")
                    Text("•")
                    Text(formattedDate(checklist.revisionDate))
                    if !checklist.approvedBy.isEmpty {
                        Text("•")
                        Text(checklist.approvedBy)
                    }
                    Spacer()
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                
                if let createdDate = checklist.createdDate {
                    Text("Started: \(formattedDateTime(createdDate))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let completionDate = checklist.completionDate {
                    Text("Completed: \(formattedDateTime(completionDate))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 20)
            
            // Items - left aligned
            VStack(spacing: 16) {
                ForEach(checklist.items) { item in
                    printItemView(item)
                    Divider()
                }
            }
        }
    }
    
    private func printItemView(_ item: ChecklistItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            switch item.type {
            case .descriptionText:
                Text(item.bodyText)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
            case .locationDetails:
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.bodyText)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let userInput = item.userInput?.text {
                        Text(userInput)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
            case .purposeDetails:
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.bodyText)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let userInput = item.userInput?.text {
                        Text(userInput)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
            case .validityDetails:
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.bodyText)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let startDate = item.validityStartDate,
                       let endDate = item.validityEndDate {
                        HStack {
                            Spacer()
                            Text("Valid: \(formattedDateTime(startDate)) - \(formattedDateTime(endDate))")
                                .font(.body)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                }
                
            case .paragraphHeader:
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.headerText)
                        .font(.headline)
                    if let supportText = item.supportText {
                        Text(supportText)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                
            case .singleLineCheck, .doubleLineCheck:
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.bodyText)
                        .font(.body)
                    if let supportText = item.supportText {
                        Text(supportText)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Checkbox options
                    if let checkOptions = item.checkOptions {
                        HStack(spacing: 20) {
                            Spacer()
                            if checkOptions.yes {
                                checkboxPrintView("Yes", isSelected: item.selectedOption == "Yes")
                            }
                            if checkOptions.no {
                                checkboxPrintView("No", isSelected: item.selectedOption == "No")
                            }
                            if checkOptions.na {
                                checkboxPrintView("N/A", isSelected: item.selectedOption == "N/A")
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func checkboxPrintView(_ option: String, isSelected: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                .resizable()
                .frame(width: 20, height: 20)
            Text(option)
                .font(.body)
        }
    }
    
    private func printChecklist() {
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = checklist.name
        printInfo.outputType = .general
        
        let printController = UIPrintInteractionController.shared
        printController.printInfo = printInfo
        
        let formatter = UIMarkupTextPrintFormatter(markupText: generateHTML())
        printController.printFormatter = formatter
        
        printController.present(animated: true)
    }
    
    private func generateHTML() -> String {
        // Generate HTML representation of the checklist
        // This would be a detailed implementation converting the checklist to HTML
        // Would you like me to include the HTML generation code?
        return ""
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
    }
    
    private func formattedDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter.string(from: date)
    }
} 