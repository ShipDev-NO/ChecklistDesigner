//
//  ViewTitleStyle.swift
//

import SwiftUI

struct ViewTitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(.white)
    }
}

extension View {
    func viewTitleStyle() -> some View {
        modifier(ViewTitleStyle())
    }
} 