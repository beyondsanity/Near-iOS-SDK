//
//  NearManager.swift
//  NearITSDK
//
//  Created by Francesco Leoni on 27/03/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

import UIKit
import NearITSDK
import UserNotifications

public enum NearRecipeTracking : String {
    case notified = "notified"
    case engaged = "engaged"
}

public protocol NearManagerDelegate {
    func manager(_ manager: NearManager, eventWithContent content: Any, trackingInfo: NITTrackingInfo);
    func manager(_ manager: NearManager, eventFailureWithError error: Error);
}

public final class NearManager: NSObject, NITManagerDelegate {
    
    private var manager: NITManager!
    public var delegate: NearManagerDelegate?
    public var profileId: String? {
        get {
            return manager.profileId()
        }
    }
    public var showBackgroundNotification: Bool {
        get {
            return manager.showBackgroundNotification
        }
        set(show) {
            manager.showBackgroundNotification = show
        }
    }
    public static let shared: NearManager = {
        let nearManager = NearManager()
        nearManager.manager = NITManager.default()
        nearManager.manager.delegate = nearManager
        return nearManager
    }()
    
    public class func setup(apiKey: String) {
        NITManager.setup(withApiKey: apiKey)
    }
    
    public func start() {
        manager.start()
    }
    
    public func stop() {
        manager.stop()
    }
    
    public func setDeviceToken(_ token: Data) {
        manager.setDeviceTokenWith(token)
    }
    
    public func refreshConfig(completionHandler: ((Error?) -> Void)?) {
        manager.refreshConfig(completionHandler: completionHandler)
    }
    
    public func processRecipeSimple(_ userInfo: [AnyHashable : Any]) -> Bool {
        if let ui = userInfo as? [String : Any] {
            return manager.processRecipeSimple(userInfo: ui)
        }
        return false
    }
    
    public func processRecipe(_ userInfo: [AnyHashable : Any], completion: ((Any?, NITTrackingInfo?, Error?) -> Void)?) -> Bool {
        if let ui = userInfo as? [String : Any] {
            return manager.processRecipe(userInfo: ui, completion: { (content, trackingInfo, error) in
                if completion != nil {
                    completion!(content, trackingInfo, error)
                }
            })
        }
        return false
    }
    
    public func sendTracking(_ trackingInfo: NITTrackingInfo?, event: String?) {
        manager.sendTracking(with: trackingInfo, event: event)
    }
    
    public func setUserData(_ key: String, value: String?, completionHandler: ((Error?) -> Void)?) {
        manager.setUserDataWithKey(key, value: value, completionHandler: completionHandler)
    }
    
    public func setBatchUserData(_ valuesDictionary : [String : Any], completionHandler: ((Error?) -> Void)?) {
        manager.setBatchUserDataWith(valuesDictionary, completionHandler: completionHandler)
    }
    
    public func setDeferredUserData(_ key: String, value: String) {
        manager.setDeferredUserDataWithKey(key, value: value)
    }
    
    public func sendEvent(_ event: NITEvent, completionHandler: ((Error?) -> Void)?) {
        manager.sendEvent(with: event, completionHandler: completionHandler)
    }
    
    public func coupons(_ completionHandler: (([NITCoupon]?, Error?) -> Void)?) {
        manager.coupons(completionHandler: completionHandler)
    }
    
    public func resetProfile() {
        manager.resetProfile()
    }
    
    public func setProfile(id: String) {
        manager.setProfileId(id)
    }
    
    public func recipes(_ completionHandler:(([NITRecipe]?, Error?) -> Void)?) {
        manager.recipes { (recipes, error) in
            if let handler = completionHandler {
                handler(recipes, error)
            }
        }
    }
    
    public func processRecipe(id: String) {
        manager.processRecipe(withId: id)
    }
    
    public func manager(_ manager: NITManager, eventFailureWithError error: Error) {
        delegate?.manager(self, eventFailureWithError: error);
    }
    
    public func manager(_ manager: NITManager, eventWithContent content: Any, trackingInfo: NITTrackingInfo) {
        delegate?.manager(self, eventWithContent: content, trackingInfo: trackingInfo)
    }
}
