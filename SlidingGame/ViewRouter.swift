//
//  ViewRouter.swift
//  SlidingGame
//
//  Created by Alvindo Tri Jatmiko on 13/08/25.
//

import Combine
import SwiftUI

class ViewRouter: ObservableObject {
    @Published var currentPage: String = "main"
    @Published var isGameOver: Bool = false
    @Published var isPlaying: Bool = false
}
