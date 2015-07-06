//
//  ViewController.swift
//  OAuth2PodApp
//
//  Created by Pascal Pfiffner on 7/6/15.
//  Copyright (c) 2015 Ossus. All rights reserved.
//

import UIKit
import p2_OAuth2


class ViewController: UIViewController
{
	lazy var oauth2 = OAuth2CodeGrant(settings: [
		"client_id": "8ae913c685556e73a16f",                         // yes, this client-id and secret will work!
		"client_secret": "60d81efcc5293fd1d096854f4eee0764edb2da5d",
		"authorize_uri": "https://github.com/login/oauth/authorize",
		"token_uri": "https://github.com/login/oauth/access_token",
		"scope": "user repo:status",
		"redirect_uris": ["ppoauthapp://oauth/callback"],            // app has registered this scheme
		"secret_in_body": true,                                      // GitHub does not accept client secret in the Authorization header
		"verbose": true,
	])
	
	@IBOutlet var imageView: UIImageView?
	@IBOutlet var signInButton: UIButton?
	@IBOutlet var forgetButton: UIButton?
	
	@IBAction func signIn(sender: UIButton?) {
		oauth2.viewTitle = "GitHub"
		oauth2.onAuthorize = { parameters in
			self.didAuthorizeWith(parameters)
		}
		oauth2.onFailure = { error in
			self.didCancelOrFail(error)
		}
		
		// change the following line to: "true" for built-in web view, "false" for Safari
		oauth2.authConfig.authorizeEmbedded = false
		oauth2.authConfig.authorizeContext = self
		oauth2.authorize()
	}
	
	@IBAction func forgetTokens(sender: UIButton?) {
		signInButton?.setTitle("Sign In", forState: .Normal)
		imageView?.hidden = true
		forgetButton?.hidden = true
		oauth2.forgetTokens()
	}
	
	
	// MARK: - Actions
	
	func didAuthorizeWith(parameters: OAuth2JSON) {
		println("Did authorize with parameters: \(parameters)")
		forgetButton?.hidden = false
		
		requestUserdata { dict, error in
			if let error = error {
				println("Fetching user data failed: \(error.localizedDescription)")
			}
			else {
				println("Fetched user data: \(dict)")
				if let username = dict?["name"] as? String {
					self.signInButton?.setTitle(username, forState: .Normal)
				}
				if let imgURL = dict?["avatar_url"] as? String, let url = NSURL(string: imgURL) {
					self.loadAvatar(url)
				}
			}
		}
	}
	
	func didCancelOrFail(error: NSError?) {
		if nil != error {
			println("Authorization went wrong: \(error!.localizedDescription)")
		}
	}
	
	func requestUserdata(callback: ((dict: NSDictionary?, error: NSError?) -> Void)) {
		requestJSON("user", callback: callback)
	}
	
	func loadAvatar(url: NSURL) {
		request(url) { data, error in
			dispatch_async(dispatch_get_main_queue()) {
				if let data = data {
					self.imageView?.image = UIImage(data: data)
					self.imageView?.hidden = false
				}
				else {
					println("Failed to load avatar: \(error?.localizedDescription)")
				}
			}
		}
	}
	
	/** Perform a request against the GitHub API and return decoded JSON or an NSError. */
	func requestJSON(path: String, callback: ((dict: NSDictionary?, error: NSError?) -> Void)) {
		let baseURL = NSURL(string: "https://api.github.com")!
		
		request(baseURL.URLByAppendingPathComponent(path)) { data, error in
			if let data = data {
				var err: NSError?
				let dict = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &err) as? NSDictionary
				dispatch_async(dispatch_get_main_queue()) {
					callback(dict: dict, error: err)
				}
			}
			else {
				dispatch_async(dispatch_get_main_queue()) {
					callback(dict: nil, error: error)
				}
			}
		}
	}
	
	func request(url: NSURL, callback: ((data: NSData?, error: NSError?) -> Void)) {
		let req = oauth2.request(forURL: url)
		req.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
		
		let session = NSURLSession.sharedSession()
		let task = session.dataTaskWithRequest(req) { data, response, error in
			callback(data: nil != error ? nil : data, error: error)
		}
		task.resume()
	}
}

