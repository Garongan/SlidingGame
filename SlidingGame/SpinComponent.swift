//
//  SpinComponent.swift
//  SlidingGame
//
//  Created by Alvindo Tri Jatmiko on 13/08/25.
//

import RealityKit

/// A component that spins the entity around a given axis.
struct SpinComponent: Component {
    let spinAxis: SIMD3<Float> = [0, 1, 0]
}
