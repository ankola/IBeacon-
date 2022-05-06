//
//  LocationBeaconManger.swift
//  BeaconDemo
//
//  Created by Savan Ankola on 26/04/22.
//

import UIKit
import CoreLocation

struct ItemConstant {
    static let nameKey = "name"
    static let iconKey = "icon"
    static let uuidKey = "uuid"
    static let majorKey = "major"
    static let minorKey = "minor"
    static let macAddress = "macAddress"
}

class Item: NSObject, NSCoding {
    let name: String
    let icon: Int
    let uuid: UUID
    let majorValue: CLBeaconMajorValue
    let minorValue: CLBeaconMinorValue
    var beacon: CLBeacon?
    let mac: String
    
    init(name: String, icon: Int, uuid: UUID, majorValue: Int, minorValue: Int,mac: String) {
        self.name = name
        self.icon = icon
        self.uuid = uuid
        self.majorValue = CLBeaconMajorValue(majorValue)
        self.minorValue = CLBeaconMinorValue(minorValue)
        self.mac = mac
    }
    
    init(dict: [String: Any]) {
        let aName = dict[ItemConstant.nameKey] as? String
        name = aName ?? ""
        
        let aUUID = dict[ItemConstant.uuidKey] as? String
        uuid = UUID(uuidString: aUUID ?? "") ?? UUID()
        
        icon = dict[ItemConstant.iconKey] as? Int ?? 0
        majorValue = CLBeaconMajorValue(dict[ItemConstant.majorKey] as? Int ?? 0)
        minorValue = CLBeaconMinorValue(dict[ItemConstant.minorKey] as? Int ?? 0)
        let macAddress = dict[ItemConstant.macAddress] as? String
        self.mac = macAddress ?? ""
    }
    
    // MARK: NSCoding
    required init(coder aDecoder: NSCoder) {
        let aName = aDecoder.decodeObject(forKey: ItemConstant.nameKey) as? String
        name = aName ?? ""
        
        let aUUID = aDecoder.decodeObject(forKey: ItemConstant.uuidKey) as? UUID
        uuid = aUUID ?? UUID()
        
        icon = aDecoder.decodeInteger(forKey: ItemConstant.iconKey)
        majorValue = UInt16(aDecoder.decodeInteger(forKey: ItemConstant.majorKey))
        minorValue = UInt16(aDecoder.decodeInteger(forKey: ItemConstant.minorKey))
        
        let macAddress = aDecoder.decodeObject(forKey: ItemConstant.macAddress) as? String
        self.mac = macAddress ?? ""
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: ItemConstant.nameKey)
        aCoder.encode(icon, forKey: ItemConstant.iconKey)
        aCoder.encode(uuid, forKey: ItemConstant.uuidKey)
        aCoder.encode(Int(majorValue), forKey: ItemConstant.majorKey)
        aCoder.encode(Int(minorValue), forKey: ItemConstant.minorKey)
    }
    
    func printModel(reflect: Mirror? = nil) {
        let mirror = reflect ?? Mirror(reflecting: self)
        if mirror.superclassMirror != nil {
            self.printModel(reflect: mirror.superclassMirror)
        }
        
        for attr in mirror.children {
            if let property_name = attr.label {
                print("\(property_name) = \(attr.value)")
            }
        }
        locationString()
    }
    
    @discardableResult func locationString() -> String {
        guard let beacon = beacon else { return "Location = Unknown" }
        let proximity = nameForProximity
        let accuracy = String(format: "%.2f", beacon.accuracy)
        
        var location = "Location = \(proximity)"
        if beacon.proximity != .unknown {
            location += " (approx. \(accuracy)m)"
        }
        
        return location
    }
    
    var nameForProximity: String {
        switch beacon?.proximity {
        case .unknown:
            return "Unknown"
        case .immediate:
            return "Immediate"
        case .near:
            return "Near"
        case .far:
            return "Far"
        case .none:
            return "None"
        @unknown default:
            return "Unknown Default"
        }
    }
}

