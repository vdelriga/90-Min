//
//  SwiftUIView.swift
//  El Marcador
//
//  Created by Victor Manuel Del Rio Garcia on 20/9/22.
//

import SwiftUI
import UserNotifications
struct MainView: View {
    @State var gdprSettings:Bool =  false
    @State var reset:Bool =  false
    var body: some View {
        VStack(alignment:.trailing){
            Menu{
                Link(destination: URL(string: "https://vmdelrio.wixsite.com/90-min/pol%C3%ADtica-de-privacidad")!) {
                    Image(systemName: "eye")
                    Text("Política de Privacidad")
                }
                
                Button(action: {
                    gdprSettings = true
                    reset.toggle()
                }, label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Ajustes Privacidad")
                })
                
            }label: {
                Label("", systemImage: "gearshape")
            }.foregroundColor(.red)
             .padding(.trailing)
            
            ZStack{
                GDPRConsent(settings: gdprSettings,reset:reset)
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
}
        
        struct SwiftUIView_Previews: PreviewProvider {
            static var previews: some View {
                MainView()
                    .previewDevice("iPhone 14 Pro")
            }
        }
        

