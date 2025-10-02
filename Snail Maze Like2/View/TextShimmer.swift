//
//  TextShimmer.swift
//  Retro Maze
//
//  Created by Williams SAADI on 02/10/2025.
//

import SwiftUI

struct TextShimmer: View {
    var text: String
    @State var animation = false
    
    var body: some View{
        ZStack{
            Text(text)
                .font(.system(size: 45, weight: .bold))
                .foregroundColor(Color.white.opacity(0.25))
            
            HStack(spacing: 0){
                ForEach(0..<text.count, id: \.self) { index in
                    Text(String(text[text.index(text.startIndex, offsetBy: index)]))
                        .font(.system(size: 45, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .mask(
                Rectangle()
                    .fill(
                        LinearGradient(gradient: .init(colors: [Color.white.opacity(0.5), Color.white, Color.white.opacity(0.5)]), startPoint: .top, endPoint: .bottom)
                    )
                    .rotationEffect(.init(degrees: 70))
                    .padding(20)
                    .offset(x: -250)
                    .offset(x: animation ? 500 : 0)
            ).onAppear {
                withAnimation(Animation.linear(duration: 5).repeatForever(autoreverses: false)) {
                    animation.toggle()
                }
            }
        }
    }
}

struct TextShimmer_Previews: PreviewProvider {
    static var previews: some View {
        TextShimmer(text: "Slice Of Digital")
    }
}
