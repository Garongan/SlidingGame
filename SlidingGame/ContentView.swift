//
//  ContentView.swift
//  SlidingGame
//
//  Created by Alvindo Tri Jatmiko on 13/08/25.
//

import RealityKit
import SwiftUI

struct ContentView: View {
    #if os(iOS)
        let playerSpeed: Float = 0.025
    #elseif os(macOS)
        let playerSpeed: Float = 0.015
    #endif

    @EnvironmentObject var viewRouter: ViewRouter
    @State var moveState: SIMD3<Float> = .zero
    @State var isDirectionOfRandomOfX = false
    @State var nextDirectionPlayerofX = false
    @State var count: Int = 1
    @State var boxes: [Entity] = []
    @State var lastBoxPosition: SIMD3<Float> = .zero
    @State var nextIndex = 0
    @State var elapsedTime: TimeInterval = 0

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
            .onTapGesture {
                nextDirectionPlayerofX.toggle()
            }
            
            VStack {
                HStack(spacing: 16) {
                    Image(systemName: nextDirectionPlayerofX ? "arrowshape.left" : "arrowshape.right")
                        .font(.title)
                        .foregroundStyle(.white)
                    
                    Text("\(Int(elapsedTime))")
                        .font(.title)
                        .foregroundStyle(.white)
                    
                    Spacer()
                }
                
                Spacer()
            }
            .padding()

            #if os(iOS)
//                VStack {
//                    Spacer()
//
//                    HStack {
//                        Button(action: {
//                            nextDirectionPlayerofX = true
//                        }) {
//                            Image(systemName: "arrowshape.left")
//                                .resizable()
//                                .frame(width: 72, height: 72)
//                                .foregroundStyle(.white)
//                        }
//
//                        Spacer()
//
//                        Button(action: {
//                            nextDirectionPlayerofX = false
//                        }) {
//                            Image(systemName: "arrowshape.right")
//                                .resizable()
//                                .frame(width: 72, height: 72)
//                                .foregroundStyle(.white)
//                        }
//                    }
//                }
//                .padding()
//                .safeAreaPadding()
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
                return .ignored
            }
            .onKeyPress(.rightArrow) {
                nextDirectionPlayerofX = false
                return .ignored
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

        for i in 0..<100 {
            let box = boxEntity.clone(recursive: true)
            box.name = "box_\(i+1)"
            if i != 0 {
                box.position = boxNextPosition(
                    i: i,
                    boxSize: boxSize
                )
            }

            lastBoxPosition = box.position
            boxes.append(box)
            rootEntity.addChild(box)
        }

        let camera = Entity()
        camera.components.set(PerspectiveCameraComponent())
        rootEntity.addChild(camera)
        let cameraLocation: SIMD3<Float> = [1, 1, 1]
        

        content.add(rootEntity)
        _ = content.subscribe(to: SceneEvents.Update.self) { event in
            playerEntity.transform.translation -= moveState
            
            camera.look(
                at: playerEntity.position,
                from: playerEntity.position + cameraLocation,
                relativeTo: nil
            )

            if playerEntity.position.y < 0 {
                viewRouter.isGameOver = true
            }

            if viewRouter.isPlaying {
                let box = boxes[nextIndex]
                let distanceToPlayerX = abs(box.position.x - playerEntity.position.x)
                let distanceToPlayerZ = abs(box.position.z - playerEntity.position.z)
                    
                if distanceToPlayerX > 1.5 || distanceToPlayerZ > 1.5 {
                    let nextPosition = boxNextPosition(
                        i: count,
                        boxSize: boxSize,
                        isStart: false
                    )

                    box.position = nextPosition
                    lastBoxPosition = nextPosition
                    count += 1
                    nextIndex = (nextIndex + 1) % boxes.count
                }
                elapsedTime += event.deltaTime
            }

        }
    }

    private func boxNextPosition(
        i: Int,
        boxSize: SIMD3<Float>,
        isStart: Bool = true,
    ) -> SIMD3<Float> {
        let randomPositionXOrZ =
            i.isMultiple(of: 3) ? Float.random(in: 0...1) : 0.5

        var nextPosition: SIMD3<Float> = .zero

        if randomPositionXOrZ < 0.5 || (isStart && i < 5) {
            nextPosition.z = lastBoxPosition.z - boxSize.z
            nextPosition.x = lastBoxPosition.x
            isDirectionOfRandomOfX = false
        } else if randomPositionXOrZ > 0.5 {
            nextPosition.x = lastBoxPosition.x - boxSize.x
            nextPosition.z = lastBoxPosition.z
            isDirectionOfRandomOfX = true
        } else {
            nextPosition = [
                isDirectionOfRandomOfX
                    ? lastBoxPosition.x - boxSize.x
                    : lastBoxPosition.x,
                lastBoxPosition.y,
                isDirectionOfRandomOfX
                    ? lastBoxPosition.z : lastBoxPosition.z - boxSize.z,
            ]
        }

        if count.isMultiple(of: 3) {
            count = 0
        }

        return nextPosition
    }
}

//#Preview {
//    ContentView()
//}
