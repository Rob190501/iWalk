//
//  CustomDivider.swift
//  iWalk
//
//  Created by Roberto Ambrosino on 04/02/25.
//

import SwiftUI

struct CustomDivider: View {
    var color: Color = .secondary.opacity(0.2)
    var height: CGFloat = 1

    var body: some View {
        Divider()
            .frame(height: height)
            .background(color)
    }
}

#Preview {
    CustomDivider()
}
