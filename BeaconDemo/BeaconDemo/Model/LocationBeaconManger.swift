//
//  LocationBeaconManger.swift
//  BeaconDemo
//
//  Created by Savan Ankola on 26/04/22.
//

import Foundation
import CoreLocation

final class LocationBeaconManger: NSObject {
    
    // MARK: - Variables
    //Private
    private var locationManager: CLLocationManager!
    static let Shared = LocationBeaconManger()
    fileprivate var timerStart: Timer!
    
    var dictRssi = [String:Any]()
    var dictMajorRssi = [String:Double]()
    var dictAvgRssi = [String:Double]()
    var dictAvgDistance = [String:Double]()
    var dictCount = [String:Int]()
    
    var staticBeaconIdealCount = 3
    
    private override init() {}
    
    func setUpLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
    }
    
    func stopScanning() {
        self.stopTimer()
        self.locationManager.rangedBeaconConstraints.forEach { beaconIdentityConstraint in
            self.locationManager.stopRangingBeacons(satisfying: beaconIdentityConstraint)
        }
        self.locationManager.monitoredRegions.forEach { beaconRegion in
            self.locationManager.stopMonitoring(for: beaconRegion)
        }
    }
    
    private func startScanning() {
        let dictResponse = self.readJsonFile(ofName: "BeaconList")
        guard dictResponse.keys.count > 0, let resultFlag = dictResponse["resultFlag"] as? Bool, resultFlag == true, let storedItems = (dictResponse["beacons"] as? [[String: Any]])?.map({ Item(dict: $0) }) else {
            return
        }
        for item in storedItems {
            startMonitoringItem(item)
        }
    }
    
    private func startMonitoringItem(_ item: Item) {
        let beaconIdentity = CLBeaconIdentityConstraint(uuid: item.uuid)
        let beaconRegion = CLBeaconRegion(beaconIdentityConstraint: beaconIdentity, identifier: item.name)
        locationManager.startMonitoring(for: beaconRegion)
        locationManager.startRangingBeacons(satisfying: beaconIdentity)
    }
    
    //MARK: Start Timer
    private func startTimer() {
        if timerStart == nil{
            timerStart = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerActionStart), userInfo: nil, repeats: true)
        }
    }
    
    private func stopTimer() {
        if timerStart != nil {
            timerStart?.invalidate()
            timerStart = nil
        }
    }
    
    private func getProximityString(proximity:CLProximity)->String{
        switch proximity {
        case .unknown:
            return "Unknown"
        case .immediate:
            return "Immediate"
        case .near:
            return "Near"
        case .far:
            return "Far"
        @unknown default:
            return "Unknown Default"
        }
    }
}

extension LocationBeaconManger : CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Failed monitoring region: \(String(describing: region)) \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) && CLLocationManager.isRangingAvailable() {
                self.startScanning()
                self.startTimer()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        
        for beacon in beacons {

            if beacon.rssi == 0 {
                continue
            }
            
            let str_Minor = "\(beacon.minor)"
            let str_Major = Double("\(beacon.major)".prefix(2)) ?? 75
            let idealCount = String("\(beacon.major)".last ?? "4")
                        
            self.setDictWithRSSI(Minor: str_Minor, Rssi: Double(beacon.rssi), Distance: beacon.accuracy, majorRssi: str_Major, idealCount: Int(idealCount) ?? 4, major: "\(beacon.major)")
            
//            str = str + "Total Beacons - \(beacons.count) \nRssi - \(beacon.rssi) \nMajor - \(beacon.major) \nMionr - \(beacon.minor) \nDistance - \(self.getProximityString(proximity: beacon.proximity)) - \(Double(beacon.accuracy)) \n\n\n"
            
//            let majorRssi = "\(be acon.major)".prefix(2)
//            let idealCount = String("\(beacon.major)".last ?? "5")
//            print("majorRssi - ", Double(majorRssi) ?? 75)
//            print("idealCount - ", Int(idealCount) ?? 4)
//            print("minor - ", beacon.minor)
//            print("idealCount - ", idealCount)
//            print("rssiUFO - ", Double(beacon.rssi))
//            print("Distance - ", beacon.accuracy)
//            print("major - ", beacon.major)
//            print("idealCount - ", idealCount)
//            print("identifier - ", beacon.uuid)
        }
    }
}

//MARK RSSI
extension LocationBeaconManger {
    //MARK: Set Dictionary RSSI
    private func setDictWithRSSI(Minor: String, Rssi: Double, Distance:Double, majorRssi:Double, idealCount: Int, major:String) {
        
        print(Rssi)
        
        if var tempArray = dictRssi[Minor] as? [[String : Any]] {
            let currentDate = Date().timeIntervalSince1970
            var tempdata = [String: Any]()
            tempdata["RSSI"] = Rssi
            tempdata["Time"] = currentDate
            tempdata["Distance"] = Distance
            tempArray.append(tempdata)
            dictRssi[Minor] = tempArray
            dictMajorRssi[Minor] = majorRssi
            
        }else{
            var tempdata = [String: Any]()
            tempdata["RSSI"] = Rssi
            tempdata["Time"] = Date().timeIntervalSince1970
            tempdata["Distance"] = Distance
            var temparray = [Any]()
            temparray.append(tempdata)
            dictRssi[Minor] = temparray
            dictMajorRssi[Minor] = majorRssi
        }
    }
    
    @objc func timerActionStart() {
//        BeaconList Update
//        NotificationCenter.default.post(name: .updateBeaconList, object: nil)
                
        if !dictRssi.isEmpty {
            self.setupDictFilterData()
            if dictAvgRssi.keys.count > 0 {
                let tempNearest = findNearest(dict: dictAvgRssi)
                if beaconMacAddress != tempNearest {
                    if let beaconMajor = dictMajorRssi[tempNearest] {
                        if let tempAvgRssi = dictAvgRssi[tempNearest] {
                            if abs(tempAvgRssi) <= beaconMajor {
                                beaconMacAddress = tempNearest
                                print("beacon found - minor value is ", tempNearest)
                                NotificationCenter.default.post(name: Notification.Name("nearest_beacon"), object: tempNearest)
                            }
                        }
                    }
                }
            } else {
                beaconMacAddress = ""
                print("beacon not found")
                NotificationCenter.default.post(name: Notification.Name("nearest_beacon"), object: "-1")
            }
        }
    }
            
    //MARK: Set Avarage Dictionary RSSI
    private func setupDictFilterData() {
        dictAvgRssi.removeAll()
        var tempDictRssi = [String:Any]()
        for (key, value) in dictRssi {
            if let tempArray = value as? [[String : Any]] {
                
                let currentDate = Date().timeIntervalSince1970
                var tempNewArray = [[String : Any]]()

                if tempArray.count >= self.staticBeaconIdealCount {
                    for dict in tempArray {
                        if let tempDate = dict["Time"] as? TimeInterval {
                            let timeDifference = currentDate - tempDate
                            if timeDifference < 6 {
                                tempNewArray.append(dict)
                            }
                        }
                    }
                } else {
                    for dict in tempArray {
                        if let tempDate = dict["Time"] as? TimeInterval {
                            let timeDifference = currentDate - tempDate
                            if timeDifference < 12 {
                                tempNewArray.append(dict)
                            }
                        }
                    }
                }
                dictCount[key] = tempNewArray.count
                if tempNewArray.count != 0 {
                    tempDictRssi[key] = tempNewArray
                    setupAvarage(mac: key, array: tempNewArray)
                }
            }
        }
        dictRssi = tempDictRssi
    }
    
    private func setupAvarage(mac: String, array:[[String:Any]]) {
        let avrRSSI = array.map({ $0["RSSI"] as! Double }).reduce(0, +)/Double(array.count)
        dictAvgRssi[mac] = avrRSSI
        let avgDistance = array.map({ $0["Distance"] as! Double }).reduce(0, +)/Double(array.count)
        dictAvgDistance[mac] = avgDistance
        
        /*  if array.count <= 5{
         let avrRSSI = array.map({ $0["RSSI"] as! Double }).reduce(0, +)/Double(array.count)
         dictAvgRssi[mac] = avrRSSI
         let avgDistance = array.map({ $0["Distance"] as! Double }).reduce(0, +)/Double(array.count)
         dictAvgDistance[mac] = avgDistance
         }else{
         var arrReverse = array
         arrReverse.reverse()
         let arrRssi = arrReverse.prefix(5)
         
         let avrRSSI = arrRssi.map({ $0["RSSI"] as! Double }).reduce(0, +)/Double(array.count)
         dictAvgRssi[mac] = avrRSSI
         let avgDistance = arrRssi.map({ $0["Distance"] as! Double }).reduce(0, +)/Double(array.count)
         dictAvgDistance[mac] = avgDistance
         }*/
    }
        
    //MARK: Find Nearest Device With AvarageRSSI
    private func findNearest(dict: [String:Double]) -> String{
        var smallest = -1000000.0
        var smallestkey = ""
//        var tempstring = ""
        for (key, value) in dict {
            if let keycount =  dictCount[key], keycount >= self.staticBeaconIdealCount {
                if value > smallest {
                    smallest = value
                    smallestkey = key
                }
            }
//            if let temparry = dictRssi[key] as? [[String : Any]]{
//                tempstring = tempstring + "\(key) \(value), count:- \(temparry.count)\n"
//            }
        }
        return smallestkey
    }
    
    //Read Json file
    func readJsonFile(ofName: String) -> [String : Any] {
        guard let strPath = Bundle.main.path(forResource: ofName, ofType: ".json") else {
            return [:]
        }
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: strPath), options: .alwaysMapped)
            let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
            if let dictJson = jsonResult as? [String : Any] {
                return dictJson
            }
        } catch {
            print("Error!! Unable to parse ")
        }
        return [:]
    }
}
