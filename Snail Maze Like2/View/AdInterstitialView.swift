//
//  AdInterstitialView.swift
//  Snail Maze like2
//
//  Created by Williams SAADI on 02/10/2025.
//

import SwiftUI
import GoogleMobileAds

struct AdInterstitialView: UIViewControllerRepresentable {
    let adUnitID: String
    @Binding var showAd: Bool
    var onAdDismissed: (() -> Void)? = nil
    
    func makeUIViewController(context: Context) -> UIViewController {
        return UIViewController() // Conteneur pour présenter l'interstitielle
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if showAd {
            presentInterstitial(from: uiViewController)
            // Réinitialiser immédiatement pour éviter les présentations multiples
            DispatchQueue.main.async {
                showAd = false
            }
        }
    }
    
    private func presentInterstitial(from controller: UIViewController) {
        let request = Request()
        InterstitialAd.load(with: adUnitID, request: request) { ad, error in
            if let error = error {
                print("❌ Erreur chargement interstitielle: \(error.localizedDescription)")
                return
            }
            
            if let ad = ad {
                ad.present(from: controller)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onAdDismissed: onAdDismissed)
    }
    
    class Coordinator: NSObject, FullScreenContentDelegate {
        var onAdDismissed: (() -> Void)?
        var currentAd: InterstitialAd?
        
        init(onAdDismissed: (() -> Void)? = nil) {
            self.onAdDismissed = onAdDismissed
        }
        
        // Called when the ad dismissed full screen content.
        func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
            print("✅ Interstitielle fermée")
            onAdDismissed?()
            currentAd = nil
        }
        
        // Called when the ad failed to present full screen content.
        func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
            print("❌ Erreur présentation interstitielle: \(error.localizedDescription)")
            currentAd = nil
        }
    }
}
