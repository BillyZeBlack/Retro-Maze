//
//  AdBannerView.swift
//  Retro Maze
//
//  Created by Williams SAADI on 01/10/2025.
//

import SwiftUI
import GoogleMobileAds

struct AdBannerView: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: adSizeFor(cgSize: CGSize(width: 320, height: 50))) 
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = rootViewControllerOfActiveScene()
        bannerView.load(Request())
        return bannerView
    }
    
    func updateUIView(_ uiView: BannerView, context: Context) {}
    
    func rootViewControllerOfActiveScene() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}
