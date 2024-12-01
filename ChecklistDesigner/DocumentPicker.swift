import SwiftUI
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {
    let mode: DocumentPickerMode
    let documentType: DocumentType
    let onExport: (URL) throws -> Void
    let onImport: (URL) -> Void
    
    private let simulatorExportPath = "/Users/fhj/Desktop/ChecklistExports"
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker: UIDocumentPickerViewController
        
        switch mode {
        case .export:
            #if targetEnvironment(simulator)
            // Create export URL
            let exportURL = URL(fileURLWithPath: simulatorExportPath)
                .appendingPathComponent(getFileName())
            
            // Create directory if needed
            do {
                try FileManager.default.createDirectory(
                    at: URL(fileURLWithPath: simulatorExportPath),
                    withIntermediateDirectories: true
                )
                
                // Export directly
                try onExport(exportURL)
                print("Exported to \(exportURL.path)")
            } catch {
                print("Error during export: \(error)")
            }
            
            picker = UIDocumentPickerViewController(forExporting: [exportURL], asCopy: true)
            #else
            // Create temporary URL for real device
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(getFileName())
            picker = UIDocumentPickerViewController(forExporting: [tempURL], asCopy: true)
            #endif
            
        case .import:
            let supportedTypes: [UTType] = [.json]
            picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        }
        
        picker.delegate = context.coordinator
        
        // Set presentation style for iPad
        if UIDevice.current.userInterfaceIdiom == .pad {
            picker.modalPresentationStyle = .formSheet
            picker.preferredContentSize = CGSize(width: 600, height: 800)
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Helper function to get appropriate filename
    private func getFileName() -> String {
        switch documentType {
        case .templates:
            return "templates.json"
        case .checklists:
            return "checklists.json"
        case .tags:
            return "tags.json"
        }
    }
    
    // Helper function to get data for export
    private func getData() -> Data {
        switch documentType {
        case .templates:
            return Data()  // This will be handled by onExport
        case .checklists:
            return Data()  // This will be handled by onExport
        case .tags:
            return Data()  // This will be handled by onExport
        }
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            switch parent.mode {
            case .export:
                do {
                    try parent.onExport(url)
                    print("Exported to: \(url.path)")
                } catch {
                    print("Error exporting: \(error)")
                }
            case .import:
                parent.onImport(url)
                print("Imported from: \(url.path)")
            }
        }
    }
} 