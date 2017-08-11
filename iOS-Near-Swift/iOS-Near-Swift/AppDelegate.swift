//
//  AppDelegate.swift
//  iOS Near Swift
//
//  Created by Francesco Leoni on 27/07/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

import UIKit
import NearITSDKSwift
import BRYXBanner
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let apiKey = loadApiKey()
        
        NITLog.setLogEnabled(true)
        NearManager.setup(apiKey: apiKey)
        NearManager.shared.delegate = self
        NearManager.shared.setDeferredUserData("gender", value: "m")
        
        requestNotificationPermissions(application: application)
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        print("Push device token: \(deviceTokenString)")
        
        NearManager.shared.setDeviceToken(deviceToken)
    }

    func loadApiKey() -> String {
        if let path = Bundle.main.path(forResource: "keys", ofType: "plist") {
            if let keys = NSDictionary(contentsOfFile: path) {
                if let apiKey = keys["apiKey"] as? String {
                    return apiKey
                }
            }
        }
        return ""
    }
    
    func handleNearContent(content: Any, trackingInfo: NITTrackingInfo) {
        if let simple = content as? NITSimpleNotification {
            
            let banner = Banner(title: "Simple notification", subtitle: simple.message, image: UIImage(named: "icona-notifica"), backgroundColor: .black, didTapBlock: nil)
            banner.dismissesOnTap = true
            banner.show()
        } else if let coupon = content as? NITCoupon {
            let banner = Banner(title: "Coupon", subtitle: coupon.name, image: UIImage(named: "icona-couponsconto"), backgroundColor: .black, didTapBlock: nil)
            banner.dismissesOnTap = true
            banner.show()
        }
    }
    
    func requestNotificationPermissions(application: UIApplication) {
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options:[.badge, .alert, .sound]) { (granted, error) in
                // Enable or disable features based on authorization.
            }
            center.delegate = self
        } else {
            // Fallback on earlier versions
            let settings = UIUserNotificationSettings(types: [.sound, .alert, .badge], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        let _ = NearManager.shared.processRecipe(userInfo, completion: { (content, trackingInfo, error) in
            if let content = content, let trackingInfo = trackingInfo {
                self.handleNearContent(content: content, trackingInfo: trackingInfo)
            }
        })
    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        if let userInfo = notification.userInfo {
            let _ = NearManager.shared.processRecipe(userInfo, completion: { (content, trackingInfo, error) in
                if let content = content, let trackingInfo = trackingInfo {
                    self.handleNearContent(content: content, trackingInfo: trackingInfo)
                }
            })
        }
    }
}

extension AppDelegate: NearManagerDelegate {
    
    func manager(_ manager: NearManager, eventWithContent content: Any, trackingInfo: NITTrackingInfo) {
        print("New Near content available")
        handleNearContent(content: content, trackingInfo: trackingInfo)
    }
    
    func manager(_ manager: NearManager, eventFailureWithError error: Error) {
        print("Near content failure")
    }
    
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        let _ = NearManager.shared.processRecipe(userInfo) { (content, trackingInfo, error) in
            if let content = content, let trackingInfo = trackingInfo {
                self.handleNearContent(content: content, trackingInfo: trackingInfo)
            }
        }
        completionHandler()
    }
}
