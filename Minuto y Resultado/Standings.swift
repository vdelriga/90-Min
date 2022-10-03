//
//  Standings.swift
//  El Marcador
//
//  Created by Victor Manuel Del Rio Garcia on 20/9/22.
//

import SwiftUI

struct Standings: View {
    @State private var standings = [StandingType]()
    @State private var table = [Position]()
    @State private var selectedStandingType = 0
    @ObservedObject var observer = Observer()
    
    
    var body: some View {
        VStack{
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
            ZStack{
                Image("PD")
                    .resizable()
                    .frame(width: 350, height: 350)
                    .blur(radius:8)
                VStack(alignment: .leading){
                    if #available(iOS 15.0, *) {
                        Picker("Favorite Color", selection: $selectedStandingType, content: {
                            Text("Total").tag(0)
                            Text("En casa").tag(1)
                            Text("Fuera de casa").tag(2)
                        }).pickerStyle(SegmentedPickerStyle())
                            .onChange(of: selectedStandingType) { newValue in
                                Task{
                                    await loadDataStandings(type: newValue)
                                }
                            }
                        
                        
                        List {
                            Section(header: headerTable()){
                                ForEach(table, id: \.position) { item in
                                    HStack{
                                        Text(String(item.position))
                                            .frame(width: 25.0, height: 25,alignment: .center)
                                            .font(.caption)
                                        Image(String(item.team.id))
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 25.0, height: 25)
                                        Text(String(item.team.shortName))
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
                                    }
                                }
                            }
                        }.listStyle(.plain)
                        .refreshable{
                            await loadDataStandings(type: selectedStandingType)
                        }
                        .onReceive(self.observer.$enteredForeground) { _ in
                            Task {
                                await loadDataStandings(type: selectedStandingType)
                            }
                        }.opacity(0.8)
                    }
                }
            }
        }
    }
    
    
    func loadDataStandings(type:Int) async {
        guard let url = URL(string: "https://api.football-data.org/v4/competitions/PD/standings")
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
                    .font(.caption)
                Text("PJ")
                    .frame(width: 25.0, height: 25,alignment: .center)
                    .font(.caption)
                Text("PG")
                    .frame(width: 25.0, height: 25,alignment: .center)
                    .font(.caption)
                Text("PP")
                    .frame(width: 25.0, height: 25,alignment: .center)
                    .font(.caption)
                Text("PE")
                    .frame(width: 25.0, height: 25,alignment: .center)
                    .font(.caption)
                Text("GF")
                    .frame(width: 25.0, height: 25,alignment: .center)
                    .font(.caption)
                Text("GC")
                    .frame(width: 25.0, height: 25,alignment: .center)
                    .font(.caption)
            }
  }
}

struct Standings_Previews: PreviewProvider {
    static var previews: some View {
        Standings()
            .previewDevice("iPhone 14")
    }
}
