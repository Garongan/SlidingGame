//
//  SlidingGameApp.swift
//  SlidingGame
//
//  Created by Alvindo Tri Jatmiko on 13/08/25.
//

import SwiftUI

@main
struct SlidingGameApp: App {
    @StateObject var viewRouter = ViewRouter()
    
    var body: some Scene {
        WindowGroup {
            VStack {
                switch viewRouter.currentPage {
                    case "main":
                        ContentView()
                            .environmentObject(viewRouter)
                    case "game_over":
                        GameOverView()
                            .environmentObject(viewRouter)
                    default:
                        ContentView()
                            .environmentObject(viewRouter)
                }
            }
        }
    }
}
