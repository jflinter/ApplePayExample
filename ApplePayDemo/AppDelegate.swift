//
//  AppDelegate.swift
//  ApplePayDemo
//
//  Created by Jack Flintermann on 12/2/14.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        application.setStatusBarStyle(UIStatusBarStyle.LightContent, animated: false)
        return true
    }
    
}

