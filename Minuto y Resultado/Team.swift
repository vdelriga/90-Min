//
//  Team.swift
//  90 Min
//
//  Created by Victor Manuel del Rio Garcia on 19/11/22.
//

import SwiftUI

struct TeamView: View {
    @Binding public var teamId: Int
    @State private var teamData = TeamData()
    @EnvironmentObject var firestoreManager: FirestoreManager
    var body: some View {
        VStack(alignment: .leading){

                Image(String(teamId))
                 .resizable()
                 .aspectRatio(contentMode: .fit)
                 .padding(/*@START_MENU_TOKEN@*/[.top, .leading, .trailing]/*@END_MENU_TOKEN@*/)
                 .frame(width: 100, height: /*@START_MENU_TOKEN@*/100.0/*@END_MENU_TOKEN@*/)
                Text(teamData.name ?? "")
                    .font(.largeTitle)
                    .padding([.leading, .trailing])
                if let urlString = teamData.website {
                    Link(destination: URL(string: urlString)!) {
                        Text("Official Website")
                    }.padding(.leading)
                }
                if let name = teamData.coach?.name {
                    Text( NSLocalizedString("CoachKey", comment: "") + ":\(name)" )
                        .padding([.leading, .trailing])

                }
                if let squad = teamData.squad {
                    List{
                        
                        Section(header: Text("Porteros")){
                            ForEach(squad, id: \.id){ item in
                                if item.position == "Goalkeeper"{
                                    VStack(alignment: .leading) {
                                        Text(item.name)
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                        Section(header: Text("Defensas")){
                            ForEach(squad, id: \.id){ item in
                                if item.position == "Defence"{
                                    VStack(alignment: .leading) {
                                        Text(item.name)
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                        Section(header: Text("Medio Centros")){
                            ForEach(squad, id: \.id){ item in
                                if item.position == "Midfield"{
                                    VStack(alignment: .leading) {
                                        Text(item.name)
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                        Section(header: Text("Delanteros")){
                            ForEach(squad, id: \.id){ item in
                                if item.position == "Offence"{
                                    VStack(alignment: .leading) {
                                        Text(item.name)
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                    }
                }
        }.task{
            getTeamData(teamId:teamId)
        }
        .opacity(/*@START_MENU_TOKEN@*/0.8/*@END_MENU_TOKEN@*/)
            .ignoresSafeArea()
            .onReceive(firestoreManager.$teamData) { teamDat in
                let now = Date.now
                //se añade la fecha de expiración en segundos(6h)
                let expiredTime = firestoreManager.teamTimestamp.addingTimeInterval(86400)
                if  let teamDataFirestore = teamDat,now<expiredTime {
                    teamData = teamDataFirestore
                }else{
                    Task{
                        await loadTeam(teamId: teamId)
                        }
                }
            }
        }
        
        func loadTeam(teamId:Int) async {
            guard let url = URL(string: "https://api.football-data.org/v4/teams/\(teamId)")
            else {
                print("Invalid URL")
                return
                }
            var request = URLRequest(url: url)
            print(url)
            request.setValue("b0212e6976094d3aa404ec2c3b6705be", forHTTPHeaderField: "X-Auth-Token")
            do {
                let (data, _) = try await URLSession.shared.data(for:request)

                if let decodedResponse =
                    try? JSONDecoder().decode(TeamData.self, from: data){
                    teamData = decodedResponse
                    firestoreManager.addTeamData(teamData)
                    firestoreManager.updateTeamData(teamId: teamData.id ?? 0)
                }
            } catch let jsonError as NSError {
                print("JSON decode failed: \(jsonError.localizedDescription)")
            }
        }
    
    func getTeamData(teamId:Int){
        firestoreManager.getTeamData(teamId:teamId)

    }
    
    struct Team_Previews: PreviewProvider {
        static var previews: some View {
            TeamView(teamId: .constant(760))
            }
    }
        
        
}

    



