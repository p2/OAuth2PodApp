//
//  AppDelegate.swift
//  OAuth2PodApp
//
//  Created by Pascal Pfiffner on 7/6/15.
//  Copyright (c) 2015 Ossus. All rights reserved.
//

import UIKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
	var window: UIWindow?
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		return true
	}
	
	func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
		if "ppoauthapp" == url.scheme || (url.scheme?.hasPrefix("com.googleusercontent.apps"))! {
			if let vc = window?.rootViewController as? ViewController {
				vc.oauth2.handleRedirectURL(url)
				return true
			}
		}
		return false
	}
}

