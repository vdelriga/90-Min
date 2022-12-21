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
    var body: some View{
            VStack(alignment: .center){
                Spacer()
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
        
                HStack {
                    VStack(alignment: .leading){
                        Text(teamData.name ?? "")
                            .font(.system(size:30))
                            .padding(.leading)
                        if let urlString = teamData.website {
                            Link(destination: URL(string: urlString)!) {
                                Text("Official Website")
                            }
                            .padding(.leading)
                        }
                    }
                    Spacer()
                    Image(String(teamId))
                            .resizable()
                            .frame(width: 70, height: 70)
                            .aspectRatio(contentMode: .fit)
                            //.clipShape(Circle())
                            //.overlay(Circle().stroke(Color.white,lineWidth:4).shadow(radius: 10))
                    Spacer()
                    
                }
                
                VStack(alignment: .leading){
                    if let squad = teamData.squad {
                        List{
                            Section(header: HStack{
                                Image("entrenador")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 25, height: 25)
                                Text("coach")
                            }){
                                if let name = teamData.coach?.name {
                                    Text(name)
                                }
                            }.headerProminence(.increased)
                            Section(header: HStack{
                                Image("portero")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 25, height: 25)
                                Text("goalkeeper")
                            }){
                                ForEach(squad, id: \.id){ item in
                                    if item.position == "Goalkeeper"{
                                        VStack(alignment: .leading) {
                                            Text(item.name)

                                        }
                                    }
                                }
                            }.headerProminence(.increased)
                            Section(header:  HStack{
                                Image("defensas")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 25, height: 25)
                                Text("defence")
                            }){
                                ForEach(squad, id: \.id){ item in
                                    if item.position == "Defence"{
                                        VStack(alignment: .leading) {
                                            Text(item.name)

                                        }
                                    }
                                }
                            }.headerProminence(.increased)
                            Section(header: HStack{
                                Image("mediocampo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 25, height: 25)
                                Text("midfield")
                            }){
                                ForEach(squad, id: \.id){ item in
                                    if item.position == "Midfield"{
                                        VStack(alignment: .leading) {
                                            Text(item.name)

                                        }
                                    }
                                }
                            }.headerProminence(.increased)
                            Section(header: HStack{
                                Image("Delantero")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 25, height: 25)
                                Text("offence")
                            })
                            {
                                ForEach(squad, id: \.id){ item in
                                    if item.position == "Offence"{
                                        VStack(alignment: .leading) {
                                            Text(item.name)

                                        }
                                    }
                                }
                            }.headerProminence(.increased)
                        }.listStyle(.plain)
                    }
                }.task{
                    getTeamData(teamId:teamId)
                }
                .opacity(/*@START_MENU_TOKEN@*/0.8/*@END_MENU_TOKEN@*/)
                .ignoresSafeArea()
                .onReceive(firestoreManager.$teamData) { teamDat in
                    let now = Date.now
                    //se añade la fecha de expiración en segundos(5 días)
                    let expiredTime = firestoreManager.teamTimestamp.addingTimeInterval(432000)
                    if  let teamDataFirestore = teamDat,now<expiredTime {
                        teamData = teamDataFirestore
                    }else{
                        Task{
                            await loadTeam(teamId: teamId)
                        }
                    }
                }
        }.ignoresSafeArea()
            .background(Color(UIColor.systemGray6))
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
                .environmentObject(FirestoreManager())
            }
    }
        
        
}

    



