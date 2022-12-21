
import Foundation
struct Defaults {
    
    init(){
        let defaults = UserDefaults.standard
        if defaults.value(forKey:"review")==nil{
            defaults.setValue(false,forKey:"review")
        }
        if defaults.value(forKey:"counter")==nil{
            defaults.setValue(0,forKey:"counter")
        }
        if defaults.value(forKey:"league")==nil{
            defaults.setValue(0,forKey:"league")
        }
        if defaults.value(forKey:"leagueS")==nil{
            defaults.setValue(0,forKey:"leagueS")
        }
    }
    
    public func setReview(mark: Bool){
        let defaults = UserDefaults.standard
        defaults.setValue(mark,forKey:"review")
    }
    public func setLeague(league: Int){
        let defaults = UserDefaults.standard
        defaults.setValue(league,forKey:"league")
    }
    public func setLeagueS(league: Int){
        let defaults = UserDefaults.standard
        defaults.setValue(league,forKey:"leagueS")
    }
    
    public func setCounter(count: Int){
        let defaults = UserDefaults.standard
        defaults.setValue(count,forKey:"counter")
    }
    
    public func getCounter()->Int {
        let defaults = UserDefaults.standard
        return defaults.integer(forKey: "counter")
    }
    public func getReview()->Bool {
        let defaults = UserDefaults.standard
        return defaults.bool(forKey: "review")
    }
    public func setDate(date:Date){
        let defaults = UserDefaults.standard
        defaults.setValue(date,forKey:"reviewDate")
    }
    public func getDate()->Date{
        let defaults = UserDefaults.standard
        return defaults.object(forKey:"reviewDate") as! Date
    }
    public func getLeague()->Int{
        let defaults = UserDefaults.standard
        return defaults.object(forKey:"league") as! Int
    }
    public func getLeagueS()->Int{
        let defaults = UserDefaults.standard
        return defaults.object(forKey:"leagueS") as! Int
    }
    
    
}

