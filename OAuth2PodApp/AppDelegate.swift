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


	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		return true
	}
	
	func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
		if "ppoauthapp" == url.scheme {
			if let vc = window?.rootViewController as? ViewController {
				vc.oauth2.handleRedirectURL(url)
				return true
			}
		}
		return false
	}
}

