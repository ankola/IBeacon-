//
//  ViewController.swift
//  BeaconDemo
//
//  Created by Savan Ankola on 19/04/22.
//

import UIKit

public var beaconMacAddress = ""

class ViewController: UIViewController {
    
    @IBOutlet weak var lblProximity: UILabel!
    @IBOutlet weak var lblDistance: UILabel!
    
    private let locationBeaconManager = LocationBeaconManger.Shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.notification(notification:)), name: Notification.Name("nearest_beacon"), object: nil)
        
        //Start Scanning
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.locationBeaconManager.setUpLocationManager()
        }
        
        //Stop Scanning
//        DispatchQueue.main.asyncAfter(deadline: .now() + 50) {
//            self.locationBeaconManager.stopScanning()
//            self.lblDistance.text = ""
//        }
    }
    
    @objc func notification(notification : NSNotification) {
        let str = "\(notification.object ?? "")"
        if str == "-1" {
            self.lblDistance.text = "beacon not found"
        } else {
            self.lblDistance.text = "Nearest Beacon Minor value\n\n\n\n" + str
        }
    }
}
