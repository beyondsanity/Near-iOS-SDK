//
//  HomeViewController.swift
//  iOS Near Swift
//
//  Created by Francesco Leoni on 27/07/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

import UIKit
import NearITSDKSwift
import CoreLocation

class HomeViewController: UIViewController {
    
    let nearManager = NearManager.shared
    let locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension HomeViewController : CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            nearManager.start()
        } else {
            nearManager.stop()
        }
    }
}
