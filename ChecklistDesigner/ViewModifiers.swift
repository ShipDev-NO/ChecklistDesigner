import SwiftUI

struct SheetPresentationModifier: ViewModifier {
    func body(content: Content) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            content
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        } else {
            content
        }
    }
}

extension View {
    func standardSheet() -> some View {
        modifier(SheetPresentationModifier())
    }
} 