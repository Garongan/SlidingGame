//
//  ContentView.swift
//  SlidingGame
//
//  Created by Alvindo Tri Jatmiko on 13/08/25.
//

import RealityKit
import SwiftUI

struct ContentView: View {
    let playerSpeed: Float = 0.025

    @EnvironmentObject var viewRouter: ViewRouter
    @State var moveState: SIMD3<Float> = .zero
    @State var isDirectionOfRandomOfX = false
    @State var nextDirectionPlayerofX = false

    var body: some View {
        ZStack {
            RealityView { content in
                content.renderingEffects.antialiasing = .none
                content.renderingEffects.cameraGrain = .disabled
                content.renderingEffects.depthOfField = .disabled
                content.renderingEffects.dynamicRange = .standard
                content.renderingEffects.motionBlur = .disabled
                createGameScene(content)
            } placeholder: {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    Spacer()
                }
            }
            .background(.black)

            #if os(iOS)
                VStack {
                    Spacer()

                    HStack {
                        Button(action: {
                            nextDirectionPlayerofX = true
                        }) {
                            Image(systemName: "arrowshape.left")
                                .resizable()
                                .frame(width: 72, height: 72)
                                .foregroundStyle(.white)
                        }

                        Spacer()

                        Button(action: {
                            nextDirectionPlayerofX = false
                        }) {
                            Image(systemName: "arrowshape.right")
                                .resizable()
                                .frame(width: 72, height: 72)
                                .foregroundStyle(.white)
                        }
                    }
                }
                .padding()
                .safeAreaPadding()
            #endif
        }
        .overlay {
            if !viewRouter.isPlaying {
                ZStack {
                    Rectangle()
                        .fill(Color.black.opacity(0.7))
                        .edgesIgnoringSafeArea(.all)

                    VStack(spacing: 16) {
                        Text("Sliding Game")
                            .font(.title)
                            .foregroundStyle(.white)
                        Text("Tap to start")
                            .foregroundStyle(.white)
                    }
                }
                .onTapGesture {
                    viewRouter.isPlaying = true
                    moveState = [
                        nextDirectionPlayerofX ? playerSpeed : 0,
                        0,
                        nextDirectionPlayerofX ? 0 : playerSpeed,
                    ]
                }
            }
        }
        .onAppear {
            if viewRouter.isPlaying {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    moveState = [
                        nextDirectionPlayerofX ? playerSpeed : 0,
                        0,
                        nextDirectionPlayerofX ? 0 : playerSpeed,
                    ]
                }
            }
        }
        .onChange(of: nextDirectionPlayerofX) {
            moveState = [
                nextDirectionPlayerofX ? playerSpeed : 0,
                0,
                nextDirectionPlayerofX ? 0 : playerSpeed,
            ]
        }
        .onChange(of: viewRouter.isGameOver) { _, newValue in
            if newValue {
                viewRouter.currentPage = "game_over"
            }
        }
        #if os(macOS)
            .focusable()
            .onKeyPress(.leftArrow) {
                nextDirectionPlayerofX = true
                print("press left")
                return .handled
            }
            .onKeyPress(.rightArrow) {
                nextDirectionPlayerofX = false
                return .handled
            }
        #endif
    }

    /// Creates a game scene and adds it to the view content.
    ///
    /// - Parameter content: The active content for this RealityKit game.
    fileprivate func createGameScene(_ content: any RealityViewContentProtocol)
    {

        let rootEntity = AnchorEntity(world: .zero)
        var simulation = PhysicsSimulationComponent()
        simulation.gravity = [0, -9.81, 0]  // gravitasi "naik" instead of turun
        rootEntity.components.set(simulation)

        let boxSize: SIMD3<Float> = [0.2, 0.2, 0.2]
        // A component that shows a red box model.
        let boxModel = ModelComponent(
            mesh: .generateBox(size: boxSize),
            materials: [SimpleMaterial(color: .gray, isMetallic: false)]
        )

        let boxCollision = CollisionComponent(
            shapes: [.generateBox(size: boxSize)],
            isStatic: true
        )
        let boxPhysicsBody = PhysicsBodyComponent(
            massProperties: .default,
            material: .default,
            mode: .static
        )

        let boxEntity = Entity()
        boxEntity.components.set([boxModel, boxCollision, boxPhysicsBody])
        var lastBoxPosition = boxEntity.position

        let playerModel = ModelComponent(
            mesh: .generateSphere(radius: 0.1),
            materials: [SimpleMaterial(color: .blue, isMetallic: false)]
        )
        let playerCollision = CollisionComponent(shapes: [
            .generateSphere(radius: 0.1)
        ])
        let playerPhysicsBody = PhysicsBodyComponent(
            massProperties: .default,
            material: .default,
            mode: .dynamic
        )

        let playerEntity = Entity()
        playerEntity.position = lastBoxPosition
        playerEntity.position.y += boxSize.y * 1.5
        playerEntity.components.set([
            playerModel, playerCollision, playerPhysicsBody,
        ])
        rootEntity.addChild(playerEntity)

        rootEntity.addChild(boxEntity)
        for i in 0..<100 {
            let box = boxEntity.clone(recursive: true)

            let randomPositionXOrZ =
                i.isMultiple(of: 3) ? Float.random(in: 0...1) : 0.5
            if randomPositionXOrZ < 0.5 || i < 5 {
                box.position.z = lastBoxPosition.z - boxSize.z
                box.position.x = lastBoxPosition.x
                isDirectionOfRandomOfX = false
            } else if randomPositionXOrZ > 0.5 {
                box.position.x = lastBoxPosition.x - boxSize.x
                box.position.z = lastBoxPosition.z
                isDirectionOfRandomOfX = true
            } else {
                box.position = [
                    isDirectionOfRandomOfX
                        ? lastBoxPosition.x - boxSize.x
                        : lastBoxPosition.x,
                    lastBoxPosition.y,
                    isDirectionOfRandomOfX
                        ? lastBoxPosition.z : lastBoxPosition.z - boxSize.z,
                ]
            }
            lastBoxPosition = box.position
            rootEntity.addChild(box)
        }

        let camera = Entity()
        camera.components.set(PerspectiveCameraComponent())
        rootEntity.addChild(camera)
        let cameraLocation: SIMD3<Float> = [1, 1, 1]

        content.add(rootEntity)
        _ = content.subscribe(to: SceneEvents.Update.self) { event in

            playerEntity.transform.translation -= moveState

            if playerEntity.position.y < 0 {
                viewRouter.isGameOver = true
            }

            camera.look(
                at: playerEntity.position,
                from: playerEntity.position + cameraLocation,
                relativeTo: nil
            )
        }
    }
}

//#Preview {
//    ContentView()
//}
