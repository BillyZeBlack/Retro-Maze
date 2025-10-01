//  MazeView.swift
//  Snail Maze like2
//
//  Created by Williams SAADI on 22/09/2025.

import SwiftUI
import UIKit
import GoogleMobileAds

struct MazeView: View {
    @State var interstitial: InterstitialAd?
    
    @StateObject var vm = MazeViewModel()
    @Environment(\.colorScheme) var colorScheme
    
    private let padding: CGFloat = 12
    private let targetSide: CGFloat = 360
    
    // Couleurs adaptatives
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.1) : Color(white: 0.96)
    }
    
    private var textColor: Color {
        colorScheme == .dark ? .white : .primary
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? .gray : .secondary
    }
    
    private var premiumColor: Color {
        colorScheme == .dark ? .yellow : .orange
    }
    
    init() {
        // Start Google Mobile Ads
        MobileAds.shared.start(completionHandler: nil)
    }
    
    
    var body: some View {
        //controls
        VStack(spacing: 12) {
            HStack{
                controls
            }
            header
            
            GeometryReader { geo in
                let drawSide = min(targetSide, min(geo.size.width, geo.size.height))
                let cols = CGFloat(vm.maze.cols)
                let rows = CGFloat(vm.maze.rows)
                
                let availableSpace = drawSide - 2 * padding
                let cell = min(availableSpace / cols, availableSpace / rows)
                
                let totalWidth = cols * cell
                let totalHeight = rows * cell
                let offX = (drawSide - totalWidth) / 2
                let offY = (drawSide - totalHeight) / 2
                
                let lineW = max(1, cell * (vm.maze.cols <= 7 ? 0.25 : 0.15))
                let ballD = max(6, cell - lineW * 1.8)
                
                ZStack {
                    MazeCanvas(
                        maze: vm.maze,
                        drawSide: drawSide,
                        padding: padding,
                        showPath: vm.showPath || vm.showSolutionAfterFailure,
                        itemPosition: vm.itemPosition,
                        itemCollected: vm.itemCollected
                    )
                    
                    PlayerBall(
                        x: offX + CGFloat(vm.playerX) * cell + cell / 2,
                        y: offY + CGFloat(vm.playerY) * cell + cell / 2,
                        diameter: ballD
                    )
                    
                    if let itemPos = vm.itemPosition, !vm.itemCollected {
                        ItemView(
                            x: offX + CGFloat(itemPos.x) * cell + cell / 2,
                            y: offY + CGFloat(itemPos.y) * cell + cell / 2,
                            size: ballD * 0.8
                        )
                    }
                    
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 24)
                                .onEnded { v in
                                    let dx = v.translation.width
                                    let dy = v.translation.height
                                    let dir: Direction = (abs(dx) > abs(dy))
                                    ? (dx > 0 ? .right : .left)
                                    : (dy > 0 ? .down : .up)
                                    vm.handleSwipe(dir)
                                }
                        )
                    
                }
                .frame(width: drawSide, height: drawSide)
                .frame(maxWidth: .infinity, maxHeight: targetSide, alignment: .center)
            }
            .frame(height: targetSide)
            
            // Indicateur de solution premium
            if vm.showSolutionAfterFailure {
                premiumSolutionIndicator
            }
            
            //controls
            VStack {
                // TODO: : A remplacer avec le bon ID de banniere : ca-app-pub-8777271534976494/7963981117
                AdBannerView(adUnitID: "ca-app-pub-3940256099942544/2435281174")
                    .frame(height: 50)
            }
            .padding()
        }
        .padding()
        .background(backgroundColor)
        .onAppear {
            vm.tone.updateUrgency(timeLeft: vm.timeLeft)
            loadInterstitialAd()
            
        }
        .onChange(of: vm.levelsCompleted) { level in
            if level > 0 && level % 5 == 0 {
                showInterstitialIfAvailable()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var header: some View {
        VStack(spacing: 8) {
            HStack {
                Text("⏱️ \(vm.formattedTime(vm.timeLeft))")
                    .font(.system(.title3, design: .rounded).monospacedDigit())
                    .foregroundColor(vm.timeLeft <= 5 ? .red : textColor)
                
                Spacer()
                
                // Indicateur premium
                if vm.hasPremiumPack {
                    Image(systemName: "crown.fill")
                        .foregroundColor(premiumColor)
                        .font(.caption)
                }
                
                if vm.requiresItem {
                    HStack(spacing: 4) {
                        Image(systemName: vm.itemCollected ? "star.fill" : "star")
                            .foregroundColor(vm.itemCollected ? .yellow : .gray)
                        Text(vm.itemCollected ? "Objet collecté" : "Objet requis")
                            .font(.caption)
                            .foregroundColor(secondaryTextColor)
                    }
                }
            }
            
            HStack {
                Text("Niveau: \(vm.levelsCompleted + 1)")
                    .font(.caption)
                    .foregroundColor(secondaryTextColor)
                
                Spacer()
                
                let currentPalier = (vm.levelsCompleted / 10) + 1
                if currentPalier >= 2 {
                    Text("Palier \(currentPalier - 1)")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .bold()
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var premiumSolutionIndicator: some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(premiumColor)
            
            Text("Solution: \(vm.formattedSolutionTime(vm.solutionTimer))s")
                .font(.headline)
                .foregroundColor(premiumColor)
                .bold()
            
            Image(systemName: "crown.fill")
                .foregroundColor(premiumColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(premiumColor.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(premiumColor, lineWidth: 1)
        )
    }
    
    private var controls: some View {
        HStack(spacing: 16) {
            Toggle("Solution", isOn: $vm.showPath)
                .toggleStyle(SwitchToggleStyle(tint: colorScheme == .dark ? .orange : .blue))
                .disabled(vm.showSolutionAfterFailure) // Désactivé pendant l'affichage premium
            
            // Bouton d'achat premium (optionnel)
            if !vm.hasPremiumPack {
                Button("Pack Premium") {
                    // Ici vous intégrerez StoreKit
                    vm.activatePremiumPack()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(LinearGradient(
                    gradient: Gradient(colors: [.yellow, .orange]),
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .cornerRadius(8)
            } else {
                Button("Réinitialiser Premium") {
                    vm.resetPremiumStatus()
                }
                .foregroundColor(.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.red, lineWidth: 1)
                )
            }
            
            
        }
        .padding(.horizontal)
    }
    // TODO: mettre le bon ID
    func loadInterstitialAd() { //ca-app-pub-8777271534976494/7424392238 
        let adUnitID = "ca-app-pub-3940256099942544/4411468910"
        
        let request = Request()
        InterstitialAd.load(with: adUnitID, request: request) { (ad, error) in
            if let error = error {
                return
            }
            self.interstitial = ad
        }
    }
    
    private func showInterstitialIfAvailable() {
        if let interstitial = interstitial {
            let root = UIApplication.shared.windows.first?.rootViewController
            interstitial.present(from: root!)
        }
    }
}
