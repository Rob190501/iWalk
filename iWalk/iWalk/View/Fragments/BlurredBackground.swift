//
//  blurredBackground.swift
//  iWalk
//
//  Created by Roberto Ambrosino on 22/02/25.
//

import SwiftUI

struct BlurredBackground: ViewModifier {
    
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    RoundedRectangle(cornerRadius: 5)
                        .foregroundStyle(colorScheme == .dark ? .black : .white)
                        .frame(width: proxy.size.width + 10, height: proxy.size.height + 5)
                        .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                    .blur(radius: 10)
                }
            )
    }
}

extension View {
    func blurredBackgorund() -> some View {
        self.modifier(BlurredBackground())
    }
}

