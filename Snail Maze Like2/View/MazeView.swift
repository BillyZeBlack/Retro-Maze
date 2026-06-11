//
//  MazeView.swift
//  Snail Maze like2
//
//  Created by Williams SAADI on 22/09/2025.
//

import SwiftUI
import UIKit
import GoogleMobileAds


struct MazeView: View {
    let premiumManager: PremiumManager

    @State var interstitial: InterstitialAd?
    @State private var isShowingPremiumSheet = false

    @StateObject private var vm: MazeViewModel
    @Environment(\.colorScheme) var colorScheme
    
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
    
    init(premiumManager: PremiumManager) {
        self.premiumManager = premiumManager
        _vm = StateObject(wrappedValue: MazeViewModel(premiumManager: premiumManager))
        MobileAds.shared.start(completionHandler: nil)
    }
    
    
    var body: some View {
        //controls
        VStack(spacing: 12) {
            HStack{
                controls
            }
            header
            
            MazeSpriteBoard(
                maze: vm.maze,
                playerX: vm.playerX,
                playerY: vm.playerY,
                showPath: vm.showPath || vm.showSolutionAfterFailure,
                itemPosition: vm.itemPosition,
                itemCollected: vm.itemCollected,
                stepDuration: vm.stepDuration,
                isDarkMode: colorScheme == .dark,
                onSwipe: vm.handleSwipe
            )
            .frame(width: targetSide, height: targetSide)
            .frame(maxWidth: .infinity, alignment: .center)
            .shadow(color: colorScheme == .dark ? .black.opacity(0.5) : .black.opacity(0.1),
                    radius: 4, x: 2, y: 2)
            
            // Indicateur de solution premium
            if vm.showSolutionAfterFailure {
                premiumSolutionIndicator
            }
            
            // Bannière conditionnelle (uniquement si pas premium)
            if premiumManager.hasLoadedEntitlements && !vm.hasPremiumPack {
                VStack {
                    AdBannerView(adUnitID: "ca-app-pub-3940256099942544/2435281174")
                        .frame(height: 50)
                }
                .padding()
            }
        }
        .padding()
        .background(backgroundColor)
        .onAppear {
            vm.tone.updateUrgency(timeLeft: vm.timeLeft)
            loadInterstitialAd()
        }
        .onChange(of: premiumManager.hasLoadedEntitlements) { _ in
            loadInterstitialAd()
        }
        .onChange(of: vm.hasPremiumPack) { _ in
            loadInterstitialAd()
        }
        .onChange(of: vm.levelsCompleted) { level in
            if !vm.hasPremiumPack && level > 0 && level % 5 == 0 {
                showInterstitialIfAvailable()
            }
        }
        .sheet(isPresented: $isShowingPremiumSheet) {
            PremiumSheetView(premiumManager: premiumManager)
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
                .disabled(vm.showSolutionAfterFailure)

            Button {
                isShowingPremiumSheet = true
            } label: {
                Label(vm.hasPremiumPack ? "Premium actif" : "Pack Premium", systemImage: vm.hasPremiumPack ? "crown.fill" : "crown")
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.yellow, .orange]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal)
    }

    func loadInterstitialAd() {
        guard premiumManager.hasLoadedEntitlements, !vm.hasPremiumPack else {
            interstitial = nil
            return
        }

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
        guard !vm.hasPremiumPack else { return }

        if let interstitial = interstitial {
            let root = UIApplication.shared.windows.first?.rootViewController
            interstitial.present(from: root!)
        }
    }
}
