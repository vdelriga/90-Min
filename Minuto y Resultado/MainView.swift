//
//  SwiftUIView.swift
//  El Marcador
//
//  Created by Victor Manuel Del Rio Garcia on 20/9/22.
//

import SwiftUI
import UserNotifications
struct MainView: View {
    var body: some View {
        ZStack{
           
            TabView {
                Home()
                    .tabItem {
                        Image("laliga")
                        Text("Directo")
                        
                    }
                Standings()
                    .tabItem {
                        Label("Clasificación",systemImage:"trophy")
                    }
                HomeChampions()
                    .tabItem {
                        Image("UEFA")
                        Text("Directo")
                        
                    }
                StandingsCL()
                    .tabItem {
                        Image("CL_TROPHY")
                        Text("Clasificación")
                    }
                
            }.accentColor(/*@START_MENU_TOKEN@*/.red/*@END_MENU_TOKEN@*/)
        }
    }
}
        
        struct SwiftUIView_Previews: PreviewProvider {
            static var previews: some View {
                MainView()
                    .previewDevice("iPhone 14 Pro")
            }
        }
        

