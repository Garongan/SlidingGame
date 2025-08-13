//
//  GameOverView.swift
//  SlidingGame
//
//  Created by Alvindo Tri Jatmiko on 13/08/25.
//

import SwiftUI

struct GameOverView: View {
    @EnvironmentObject var viewRouter: ViewRouter
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.7))
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 16) {
                Text("Sliding Game")
                    .font(.title)
                    .foregroundStyle(.white)
                Text("Game Over")
                    .foregroundStyle(.white)
                Text("Tap to restart")
                    .foregroundStyle(.white)
            }
        }
        .onTapGesture {
            viewRouter.isGameOver = false
            viewRouter.currentPage = "main"
        }
    }
}

#Preview {
    GameOverView()
}
