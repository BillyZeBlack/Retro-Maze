//
//  LaunchPageView.swift
//  Retro Maze
//
//  Created by Williams SAADI on 02/10/2025.
//

import SwiftUI

struct LaunchPage: View {
    @State var timerFinish = false
    
    var body: some View {
        VStack(spacing: 25) {
            if timerFinish {
                withAnimation {
                    MazeView()
                }.transition(.slide)
                
            } else {
                VStack {
                    Spacer()
                    TextShimmer(text: "Retro Maze")
                        .preferredColorScheme(.dark)
                    Spacer()
                    Image("slice of digital - NB - fond noir")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: UIScreen.main.bounds.size.width, height: 100)
                }
            }
        }
        .onAppear{
            DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
            timerFinish = true
            })
        }
    }
}

struct launchPage_Previews: PreviewProvider {
    static var previews: some View {
        LaunchPage()
    }
}
