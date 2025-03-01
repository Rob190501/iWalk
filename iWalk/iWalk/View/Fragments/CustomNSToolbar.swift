//
//  ToolbarContent.swift
//  iWalk
//
//  Created by Roberto Ambrosino on 05/02/25.
//
import SwiftUI

struct CustomNSToolbar<CustomIcon: View, CustomView: View>: ViewModifier {
    
    var title: String
    var customIcon: () -> CustomIcon
    var customView: (() -> CustomView)?
    
    private var placement: ToolbarItemPlacement {
        customView == nil ? .topBarLeading : .principal
    }

    func body(content: Content) -> some View {
        content
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: placement) {
                    HStack {
                        customIcon()
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
    func customNSToolbar<CustomIcon: View, CustomView: View>(
        title: String,
        @ViewBuilder customIcon: @escaping () -> CustomIcon,
        @ViewBuilder customView: @escaping () -> CustomView
    ) -> some View {
        self.modifier(CustomNSToolbar(title: title, customIcon: customIcon, customView: customView))
    }
    
    
    func customNSToolbar<CustomIcon: View>(
        title: String,
        @ViewBuilder customIcon: @escaping () -> CustomIcon
    ) -> some View {
        self.modifier(CustomNSToolbar<CustomIcon, EmptyView>(title: title, customIcon: customIcon, customView: nil))
    }
}
