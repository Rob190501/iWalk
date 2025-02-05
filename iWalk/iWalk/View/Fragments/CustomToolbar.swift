//
//  ToolbarContent.swift
//  iWalk
//
//  Created by Roberto Ambrosino on 05/02/25.
//
import SwiftUI

struct ToolbarModifier<CustomView: View>: ViewModifier {
    var icon: String
    var title: String
    var customView: (() -> CustomView)?
    
    private var placement: ToolbarItemPlacement {
        customView == nil ? .topBarLeading : .principal
    }
    
    init(icon: String, title: String) where CustomView == EmptyView {
        self.icon = icon
        self.title = title
        self.customView = nil
    }
    
    init(icon: String, title: String, customView: @escaping () -> CustomView) {
        self.icon = icon
        self.title = title
        self.customView = customView
    }

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: placement) {
                    HStack {
                        Image(systemName: icon)
                            .foregroundStyle(.tint)
                            .font(.title)
                            .bold()
                        Text(title)
                            .font(.largeTitle)
                            .bold()
                        if let customView {
                            Spacer()
                            customView()
                        }
                    }
                }
            }
    }
}



extension View {
    func customToolbar<CustomView: View>(
        icon: String,
        title: String,
        customView: @escaping () -> CustomView
    ) -> some View {
        self.modifier(ToolbarModifier(icon: icon, title: title, customView: customView))
    }
    
    
    func customToolbar(icon: String, title: String) -> some View {
        self.modifier(ToolbarModifier<EmptyView>(icon: icon, title: title))
    }
}
