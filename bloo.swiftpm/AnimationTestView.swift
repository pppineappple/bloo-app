//
//  animation.swift
//  bloo
//
//  Created by Shin seungah on 2/21/26.
//

import SwiftUI
import SpriteKit

// MARK: - Background droplet animation scene (SpriteKit)
final class DropletScene: SKScene {
    private let core = SKShapeNode(circleOfRadius: 1)
    private var droplets: [SKShapeNode] = []

    private var lastSpawnTime: TimeInterval = 0
    private var lastUpdateTime: TimeInterval = 0

    // MARK: - Pacing
    // Aim: calm background animation that reaches a "full" core in ~30 minutes.
    // You can temporarily speed this up for demos by lowering `targetFillDuration`.
    private let targetFillDuration: TimeInterval = 30 * 60

    // How often to spawn droplets (seconds). Will be derived from targetFillDuration.
    // (If you want more/less density, tweak `targetAbsorbedForFullCore`.)
    private var spawnInterval: TimeInterval { targetFillDuration / Double(targetAbsorbedForFullCore) }

    // Number of absorbed droplets we treat as "full" (maps to maxCoreRadius).
    private let targetAbsorbedForFullCore: Int = 900

    // Keep the live droplet count reasonable for performance.
    private let maxDroplets = 70

    private var absorbedCount: Int = 0
    private var coreRadius: CGFloat = 0

    // Core size tuning
    private let baseCoreRadius: CGFloat = 18   // initial visible size
    private let growthFactor: CGFloat = 2.8    // how fast it grows with absorbedCount

    // Tuning (units ~ points/second)
    private let pullStrength: CGFloat = 22.0
    private let maxCoreRadius: CGFloat = 90
    private let absorbRadius: CGFloat = 26

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill

        core.fillColor = .systemPink.withAlphaComponent(0.22)
        core.strokeColor = .clear
        core.position = CGPoint(x: size.width / 2, y: size.height / 2)

        coreRadius = baseCoreRadius
        core.path = CGPath(
            ellipseIn: CGRect(x: -coreRadius, y: -coreRadius, width: coreRadius * 2, height: coreRadius * 2),
            transform: nil
        )

        addChild(core)

        // Jelly-like idle wobble (very subtle)
        startIdleWobble()

        view.ignoresSiblingOrder = true
    }

    override func didChangeSize(_ oldSize: CGSize) {
        core.position = CGPoint(x: size.width / 2, y: size.height / 2)
    }

    override func update(_ currentTime: TimeInterval) {
        // Delta time (seconds) for frame-rate independent motion
        let dt: CGFloat
        if lastUpdateTime == 0 {
            dt = 1.0 / 60.0
        } else {
            dt = max(0.0, min(1.0 / 20.0, CGFloat(currentTime - lastUpdateTime)))
        }
        lastUpdateTime = currentTime

        // 1) spawn
        if currentTime - lastSpawnTime > spawnInterval {
            lastSpawnTime = currentTime
            if droplets.count < maxDroplets {
                spawnDroplet()
            }
        }

        // 2) pull + absorb
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        var alive: [SKShapeNode] = []
        var absorbedThisFrame = 0
        alive.reserveCapacity(droplets.count)

        for d in droplets {
            let dx = center.x - d.position.x
            let dy = center.y - d.position.y
            let dist = max(1, sqrt(dx * dx + dy * dy))

            if dist < absorbRadius {
                d.removeFromParent()
                absorbedCount += 1
                absorbedThisFrame += 1
                continue
            }

            let nx = dx / dist
            let ny = dy / dist

            // Gentle pull toward center (points/sec * dt)
            d.position.x += (nx * pullStrength) * dt
            d.position.y += (ny * pullStrength) * dt

            d.alpha = 0.2 + min(0.8, 120.0 / dist)
            alive.append(d)
        }

        droplets = alive

        // Jelly pulse when droplets merge into the core
        if absorbedThisFrame > 0 {
            triggerPulse(count: absorbedThisFrame)
        }

        // 3) grow the core
        coreRadius = min(maxCoreRadius, baseCoreRadius + growthFactor * sqrt(CGFloat(absorbedCount)))
        core.path = CGPath(
            ellipseIn: CGRect(x: -coreRadius, y: -coreRadius, width: coreRadius * 2, height: coreRadius * 2),
            transform: nil
        )

        // 4) keep it calm: once "full", just stay near max (no reset)
        // (If you ever want a looping grow/reset cycle, bring back softReset().)
    }

    private func spawnDroplet() {
        let r: CGFloat = CGFloat.random(in: 2.5...6.0)
        let d = SKShapeNode(circleOfRadius: r)
        d.fillColor = .systemPink.withAlphaComponent(0.16)
        d.strokeColor = .clear

        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let angle = CGFloat.random(in: 0..<(2 * .pi))
        let bigR = max(size.width, size.height) * 0.7 + 60

        d.position = CGPoint(
            x: center.x + cos(angle) * bigR,
            y: center.y + sin(angle) * bigR
        )

        addChild(d)
        droplets.append(d)
    }

    private func startIdleWobble() {
        // A gentle, continuous wobble so the core feels "alive".
        // Uses non-uniform scaling to mimic a soft blob.
        let stretch = SKAction.scaleX(to: 1.06, y: 0.94, duration: 1.2)
        stretch.timingMode = .easeInEaseOut
        let squash = SKAction.scaleX(to: 0.94, y: 1.06, duration: 1.2)
        squash.timingMode = .easeInEaseOut
        let wobble = SKAction.sequence([stretch, squash])
        core.run(.repeatForever(wobble), withKey: "idleWobble")
    }

    private func triggerPulse(count: Int) {
        // A short elastic pulse when droplets are absorbed.
        // More absorbed at once -> slightly stronger pulse.
        let intensity = min(0.06, 0.015 + CGFloat(count) * 0.008)

        core.removeAction(forKey: "pulse")

        let up = SKAction.scaleX(to: 1.0 + intensity, y: 1.0 - intensity, duration: 0.10)
        up.timingMode = .easeOut
        let overshoot = SKAction.scaleX(to: 1.0 - intensity * 0.6, y: 1.0 + intensity * 0.6, duration: 0.14)
        overshoot.timingMode = .easeInEaseOut
        let settle = SKAction.scale(to: 1.0, duration: 0.18)
        settle.timingMode = .easeInEaseOut

        // Tiny rotational jiggle makes it feel more "gel" than "balloon"
        let rot1 = SKAction.rotate(byAngle: 0.05, duration: 0.10)
        rot1.timingMode = .easeOut
        let rot2 = SKAction.rotate(byAngle: -0.08, duration: 0.14)
        rot2.timingMode = .easeInEaseOut
        let rot3 = SKAction.rotate(toAngle: 0, duration: 0.18)
        rot3.timingMode = .easeInEaseOut

        let scaleSeq = SKAction.sequence([up, overshoot, settle])
        let rotSeq = SKAction.sequence([rot1, rot2, rot3])
        core.run(.group([scaleSeq, rotSeq]), withKey: "pulse")
    }

    private func softReset() {
        absorbedCount = 0
        let shrink = SKAction.customAction(withDuration: 0.35) { [weak self] _, _ in
            guard let self else { return }
            self.coreRadius *= 0.92
            self.core.path = CGPath(
                ellipseIn: CGRect(x: -self.coreRadius, y: -self.coreRadius, width: self.coreRadius * 2, height: self.coreRadius * 2),
                transform: nil
            )
        }
        core.run(shrink)
    }
}

// MARK: - A blank test view you can present anywhere
struct AnimationTestView: View {
    @State private var scene: DropletScene = {
        let s = DropletScene()
        // Size will be overridden by SpriteView at runtime; this is just for Preview.
        s.size = CGSize(width: 390, height: 844)
        s.backgroundColor = .clear
        return s
    }()

    var body: some View {
        ZStack {
            // Background animation
            SpriteView(scene: scene, options: [.allowsTransparency])
                .ignoresSafeArea()
                .opacity(0.6)

            // Foreground dummy UI (for readability testing)
            VStack(spacing: 12) {
                Text("Home")
                    .font(.largeTitle.bold())
                Text("Animation playground")
                    .font(.subheadline)
                    .opacity(0.8)
                Spacer().frame(height: 24)
                Button("Test Button") {}
                    .buttonStyle(.borderedProminent)
            }
            .padding(24)
        }
        .onAppear {
            scene.isPaused = false
        }
        .onDisappear {
            scene.isPaused = true
        }
    }
}

#Preview {
    AnimationTestView()
}
