//
//  Standings.swift
//  El Marcador
//
//  Created by Victor Manuel Del Rio Garcia on 20/9/22.
//

import SwiftUI

struct Standings: View {
    @EnvironmentObject var firestoreManager: FirestoreManager
    @State private var standings = [StandingType]()
    @State private var table = [Position]()
    @State private var selectedStandingType = 0
    @ObservedObject var observer = Observer()
    @State private var selectedLeagueS = Home.defaults.getLeagueS()
    
    
    var body: some View {
        VStack{
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
            Picker("Favorite League", selection: $selectedLeagueS, content: {
                VStack {
                    Image("laliga")
                }.tag(0)
                VStack{
                    Image("PL")
                }.tag(1)
                VStack{
                    Image("BL1")
                }.tag(2)
                VStack{
                    Image("SA1")
                }.tag(3)
                VStack{
                    Image("PPLI")
                }.tag(4)

            }).pickerStyle(SegmentedPickerStyle())
                .onChange(of: selectedLeagueS) { newValue in
                    Task{
                        Home.defaults.setLeagueS(league:newValue)
                        //await loadDataStandings(type: newValue,league:selectedLeagueS)
                        getStandings(league:selectedLeagueS)
                    }
                }
                VStack(alignment: .leading){
                    if #available(iOS 15.0, *) {
                        Picker("Favorite Color", selection: $selectedStandingType, content: {
                            Text("totalKey").tag(0)
                            Text("homeKey").tag(1)
                            Text("awayKey").tag(2)
                        }).pickerStyle(SegmentedPickerStyle())
                            .onChange(of: selectedStandingType) { newValue in
                                Task{
                                    //await loadDataStandings(type: newValue,league:selectedLeagueS)
                                    getStandings(league:selectedLeagueS)
                                }
                            }
                        
                        
                        List {
                            Section(header: headerTable()){
                                ForEach(table, id: \.position) { item in
                                    HStack{
                                        Text(String(item.position))
                                            .frame(width: 25.0, height: 25,alignment: .center)
                                            .font(.caption)
                                        Image(String(item.team.id ?? 0))
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 25.0, height: 25)
                                        Text(String(item.team.shortName ?? "-"))
                                            .frame(width:86, height:25,alignment: .leading)
                                            .font(.caption)
                                        Text(String(item.points))
                                            .frame(width: 25.0, height: 25,alignment: .center)
                                            .font(.caption)
                                            .background(Color.gray)
                                            .clipShape(RoundedRectangle(cornerRadius:5))
                                        Text(String(item.playedGames))
                                            .frame(width: 25.0, height: 25,alignment: .center)
                                            .font(.caption)
                                        Text(String(item.won))
                                            .frame(width: 25.0, height: 25,alignment: .center)
                                            .font(.caption)
                                        Text(String(item.lost))
                                            .frame(width: 25.0, height: 25,alignment: .center)
                                            .font(.caption)
                                        Text(String(item.draw))
                                            .frame(width: 25.0, height: 25,alignment: .center)
                                            .font(.caption)
                                        Text(String(item.goalsFor))
                                            .frame(width: 25.0, height: 25,alignment: .center)
                                            .font(.caption)
                                        Text(String(item.goalsAgainst))
                                            .frame(width: 25.0, height: 25,alignment: .center)
                                            .font(.caption)
                                    }.listRowBackground(Color(UIColor.systemGray6))
                                }
                            }
                        }.listStyle(.plain)
                        .refreshable{
                            getStandings(league:selectedLeagueS)
                        }
                        .onReceive(self.observer.$enteredForeground) { _ in
                            Task {
                                await loadDataStandings(type: selectedStandingType, league:selectedLeagueS)
                                getStandings(league:selectedLeagueS)
                            }
                        }.opacity(0.8)
                    }
                }.onReceive(firestoreManager.$standings) { standingsFirestore in
                    if standingsFirestore.standings.count > 0 {
                        let now = Date.now
                        //se añade la fecha de expiración en segundos(30s)
                        let expiredTime = firestoreManager.standingsTimestamp.addingTimeInterval(30)
                        if now  < expiredTime {
                            print("Información de clasificación cacheada")
                            standings = standingsFirestore.standings
                            table = standings[selectedStandingType].table
                        }else{
                            Task{
                                await loadDataStandings(type: selectedStandingType,league:selectedLeagueS)
                            }
                        }
                    }
                }

            }.background(Color(UIColor.systemGray6))
    }
    
    func getStandings(league:Int){
        firestoreManager.getStandings(league)
    }
    
    
    func loadDataStandings(type:Int,league:Int) async {
        var url: String = ""
        switch(league){
        case 0:url = "https://api.football-data.org/v4/competitions/PD/standings"
        case 1:url = "https://api.football-data.org/v4/competitions/PL/standings"
        case 2:url = "https://api.football-data.org/v4/competitions/BL1/standings"
        case 3:url = "https://api.football-data.org/v4/competitions/SA/standings"
        case 4:url = "https://api.football-data.org/v4/competitions/PPL/standings"
        default: url = "https://api.football-data.org/v4/competitions/PD/standings"
        }
        guard let url = URL(string: url)
        else {
            print("Invalid URL")
            return
        }
        var request = URLRequest(url: url)
        request.setValue("b0212e6976094d3aa404ec2c3b6705be", forHTTPHeaderField: "X-Auth-Token")
        do {
            let (data, _) = try await URLSession.shared.data(for:request)
            
            if let decodedResponse =
                try? JSONDecoder().decode(Standing.self, from: data){
                standings = decodedResponse.standings
                table = standings[type].table
                firestoreManager.addStandings(decodedResponse,league)
                firestoreManager.updateStandings(league)
                
            }
        } catch let jsonError as NSError {
            print("JSON decode failed: \(jsonError.localizedDescription)")
        }
    }

}
struct headerTable: View {
  var body: some View {
      
        HStack{
                Text("")
                    .frame(width: 25.0, height: 25,alignment: .center)
                    .font(.caption)
                Text("")
                    .frame(width: 25.0, height: 25)
                Text("")
                    .frame(width:86, height:25,alignment: .center)
                    .font(.caption)
                Text("PTS")
                    .frame(width: 25.0, height: 25,alignment:.center)
                    .font(.caption.bold())
                Text("PJ")
                    .frame(width: 25.0, height: 25,alignment: .center)
                    .font(.caption.bold())
                Text("PG")
                    .frame(width: 25.0, height: 25,alignment: .center)
                    .font(.caption.bold())
                Text("PP")
                    .frame(width: 25.0, height: 25,alignment: .center)
                    .font(.caption.bold())
                Text("PE")
                    .frame(width: 25.0, height: 25,alignment: .center)
                    .font(.caption.bold())
                Text("GF")
                    .frame(width: 25.0, height: 25,alignment: .center)
                    .font(.caption.bold())
                Text("GC")
                    .frame(width: 25.0, height: 25,alignment: .center)
                    .font(.caption.bold())
            }
  }
}

struct Standings_Previews: PreviewProvider {
    static var previews: some View {
        Standings()
            .previewDevice("iPhone 14")
    }
}
