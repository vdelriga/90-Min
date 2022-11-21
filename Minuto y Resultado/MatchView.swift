//
//  MatchView.swift
//  90 Min
//
//  Created by Victor Manuel del Rio Garcia on 19/11/22.
//

import SwiftUI

struct MatchView: View {
    let homeTeam:Team
    let awayTeam:Team
    var body: some View {
        Menu(content:{
            Button(action: {
                TeamView(teamId: homeTeam.id ?? 0)
            }, label: {
                Image(String(homeTeam.id ?? 0))
                Text(homeTeam.name ?? "")
            })
            
            Button(action: {
                TeamView(teamId: awayTeam.id ?? 0)
            }, label: {
                Image(String(awayTeam.id ?? 0))
                Text(awayTeam.name ?? "")
            })
            
        }){
            
        }
    }
}

/*struct MatchView_Previews: PreviewProvider {
    static var previews: some View {
        MatchView()
    }
}*/
