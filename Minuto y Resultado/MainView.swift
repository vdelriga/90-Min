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
                    Text("privacyPolicyKey")
                }
                
                Button(action: {
                    gdprSettings = true
                    reset.toggle()
                }, label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("privacySettingsKey")
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
                            Image(systemName:"soccerball.inverse")
                            Text(NSLocalizedString("liveItem", comment:""))
                            
                        }
                    Standings()
                        .tabItem {
                            Image(systemName: "trophy")
                            Text(NSLocalizedString("standingsItem",comment:""))
                        }
                    HomeChampions()
                        .tabItem {
                            Image("UEFA")
                            Text(NSLocalizedString("liveItem", comment:""))
                            
                        }
                    StandingsCL()
                        .tabItem {
                            Image("CL_TROPHY")
                            Text(NSLocalizedString("standingsItem",comment:""))
                        }
                }.accentColor(/*@START_MENU_TOKEN@*/.red/*@END_MENU_TOKEN@*/)
               
            }
        }.background(Color(UIColor.systemGray6))
    }
}
        
        struct SwiftUIView_Previews: PreviewProvider {
            static var previews: some View {
                MainView()
                    .previewDevice("iPhone 14 Pro")
            }
        }
        

