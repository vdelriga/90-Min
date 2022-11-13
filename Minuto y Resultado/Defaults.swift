
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
    }
    
    public func setReview(mark: Bool){
        let defaults = UserDefaults.standard
        defaults.setValue(mark,forKey:"review")
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
    
}

