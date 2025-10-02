//
//  Snail_Maze_like2App.swift
//  Snail Maze like2
//
//  Created by Williams SAADI on 22/09/2025.
//

import SwiftUI
import GoogleMobileAds

@main
struct Snail_Maze_like2App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            LaunchPage()
        }
    }
    
    class AppDelegate: NSObject, UIApplicationDelegate {
        func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
            MobileAds.shared.start(completionHandler: nil)
            return true
        }
    }
    
}
