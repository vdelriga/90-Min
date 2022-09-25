//
//  SwiftUIView.swift
//  El Marcador
//
//  Created by Victor Manuel Del Rio Garcia on 20/9/22.
//

import SwiftUI
struct MainView: View {
    var body: some View {
        TabView {
            Home()
                .tabItem {
                    Label("En directo", systemImage: "soccerball")
                        
                }
            Standings()
                .tabItem {
                    Label("Clasificación",systemImage:"trophy")
                }
        }.accentColor(/*@START_MENU_TOKEN@*/.red/*@END_MENU_TOKEN@*/)
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .previewDevice("iPhone 14 Pro")
    }
}
