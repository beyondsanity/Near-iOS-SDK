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
import PKHUD

class HomeViewController: UIViewController {
    
    let nearManager = NearManager.shared
    let locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Home"
        UIApplication.shared.statusBarStyle = .lightContent
        
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        tabBarController?.tabBar.tintColor = UIColor(red: 159/255, green: 146/255, blue: 255/255, alpha: 1.0)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func tapRefreshConfiguration(_ sender: Any) {
        HUD.show(.progress)
        nearManager.refreshConfig { (error) in
            HUD.hide()
        }
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
