

import SwiftUI

struct StandingsWC: View {
    @State private var standings = [StandingGroup]()
    @EnvironmentObject var firestoreManager: FirestoreManager
    @ObservedObject var observer = Observer()
    
    
    var body: some View {
        VStack{
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                VStack(alignment: .leading){
                    if #available(iOS 15.0, *) {
                        
                        List {
                            ForEach(standings, id:\.group){ item in
                                Section(header: headerTableWC(group:getGroup(group:item.group))){
                                    ForEach(item.table, id: \.position) { item in
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
                            }
                        }.listStyle(.plain)
                            .refreshable{
                                getStandingsCL()
                            }
                            .onReceive(self.observer.$enteredForeground) { _ in
                                Task {
                                    getStandingsCL()
                                    //await loadDataStandings()
                                    
                                }
                            }
                            .opacity(0.8)
                    }
                }
        }.background(Color(UIColor.systemGray6))
            .onReceive(firestoreManager.$standingsWC) { standingsWCFirestore in
                if standingsWCFirestore.standings.count > 0 {
                    let now = Date.now
                    //se a??ade la fecha de expiraci??n en segundos(30s)
                    let expiredTime = firestoreManager.standingsWCTimestamp.addingTimeInterval(30)
                    if now  < expiredTime {
                        print("Informaci??n de clasificaci??n cacheada")
                        standings = standingsWCFirestore.standings
                    }else{
                        Task{
                            await loadDataStandings()
                        }
                    }
                }
            }
            
    }
    
    func getGroup(group:String)->String{
        switch(group){
        case "GROUP_A": return NSLocalizedString("groupKey",comment:"") + " A"
        case "GROUP_B": return NSLocalizedString("groupKey",comment:"") + " B"
        case "GROUP_C": return NSLocalizedString("groupKey",comment:"") + " C"
        case "GROUP_D": return NSLocalizedString("groupKey",comment:"") + " D"
        case "GROUP_E": return NSLocalizedString("groupKey",comment:"") + " E"
        case "GROUP_F": return NSLocalizedString("groupKey",comment:"") + " F"
        case "GROUP_G": return NSLocalizedString("groupKey",comment:"") + " G"
        case "GROUP_H": return NSLocalizedString("groupKey",comment:"") + " H"
        default: return ""
        }
    }
    
    
    func loadDataStandings() async {
        guard let url = URL(string: "https://api.football-data.org/v4/competitions/WC/standings")
        else {
            print("Invalid URL")
            return
        }
        var request = URLRequest(url: url)
        request.setValue("b0212e6976094d3aa404ec2c3b6705be", forHTTPHeaderField: "X-Auth-Token")
        do {
            let (data, _) = try await URLSession.shared.data(for:request)
            
            if let decodedResponse =
                try? JSONDecoder().decode(StandingCL.self, from: data){
                standings = decodedResponse.standings
                firestoreManager.addStandingsWC(decodedResponse)
                firestoreManager.updateStandingsWC()
            }
        } catch let jsonError as NSError {
            print("JSON decode failed: \(jsonError.localizedDescription)")
        }
    }
    
    
    func getStandingsCL(){
        firestoreManager.getStandingsWC()
    }


}


struct headerTableWC: View {
  let group:String
  var body: some View {
        HStack{
                Text("")
                    .frame(width: 25.0, height: 25,alignment: .center)
                    .font(.caption)
                Text("")
                    .frame(width: 25.0, height: 25)
                Text(group)
                    .frame(width:86, height:25,alignment: .center)
                    .font(.caption.bold())
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

struct StandingsWC_Previews: PreviewProvider {
    static var previews: some View {
        StandingsWC()
            .previewDevice("iPhone 14")
            .environmentObject(FirestoreManager())
    }
}
