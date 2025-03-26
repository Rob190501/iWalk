//
//  LavaLampView.swift
//  iWalk
//
//  Created by Roberto Ambrosino on 18/02/25.
//
import SwiftUI

struct LavaLampView: View {
    
    var frame: CGSize
    var blobs: Int
        
    
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<blobs, id: \.self) { i in
                    LavaBlob(frame: frame)
                }
            }
            .blur(radius: 20)
        }
    }
    
}

struct LavaBlob: View {
    var frame: CGSize
    @State private var position: CGPoint = .zero
    
    var body: some View {
        Circle()
            .foregroundStyle(.tint)
            .frame(width: CGFloat.random(in: 70...170))
            .position(position)
            .onAppear {
                position = randomPosition()
                startMoving()
            }
    }
    
    /// Genera una nuova posizione casuale nell'area dello schermo
    private func randomPosition() -> CGPoint {
        guard frame.height >= 100 else {
            return CGPoint(
                x: CGFloat.random(in: 0...frame.width),
                y: CGFloat.random(in: 0...frame.height)
            )
        }
        return CGPoint(
            x: CGFloat.random(in: 0...frame.width),
            y: CGFloat.random(in: 0...frame.height-100)
        )
    }
    
    /// Sposta la bolla in una nuova posizione
    private func moveBlob() {
        withAnimation(Animation.easeInOut(duration: 25)) {
            position = randomPosition()
        }
    }
    
    /// Sposta la bolla in una nuova posizione ogni tot secondi
    private func startMoving() {
        moveBlob()
        Timer.scheduledTimer(withTimeInterval: Double.random(in: 20...25), repeats: true) { _ in
            moveBlob()
        }
    }
}

struct LavaTestView: View {
    var body: some View {
        GeometryReader { geometry in
        
            ZStack {
                LavaLampView(frame: geometry.size, blobs: 12)
                VStack {
                    Text("Test")
                        .font(.largeTitle)
                        .bold()
                    Text("Lava Lamp")
                        .foregroundStyle(.tint)
                        .font(.largeTitle)
                        .bold()
                        .padding(.vertical, 5)
                        .padding(.horizontal, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .foregroundStyle(.white)
                                .blur(radius: 20)
                        )
                    
                }
            }
        }
    }
}

#Preview {
    LavaTestView()
}
