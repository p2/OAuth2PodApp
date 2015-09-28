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
	var oauth2 = OAuth2CodeGrant(settings: [
		"client_id": "8ae913c685556e73a16f",                         // yes, this client-id and secret will work!
		"client_secret": "60d81efcc5293fd1d096854f4eee0764edb2da5d",
		"authorize_uri": "https://github.com/login/oauth/authorize",
		"token_uri": "https://github.com/login/oauth/access_token",
		"scope": "user repo:status",
		"redirect_uris": ["ppoauthapp://oauth/callback"],            // app has registered this scheme
		"secret_in_body": true,                                      // GitHub does not accept client secret in the Authorization header
		"verbose": true,
	] as OAuth2JSON)
	
	@IBOutlet var imageView: UIImageView?
	@IBOutlet var signInEmbeddedButton: UIButton?
	@IBOutlet var signInSafariButton: UIButton?
	@IBOutlet var forgetButton: UIButton?
	
	@IBAction func signInEmbedded(sender: UIButton?) {
		oauth2.authConfig.authorizeEmbedded = true
		signIn(sender)
	}
	
	@IBAction func signInSafari(sender: UIButton?) {
		oauth2.authConfig.authorizeEmbedded = false
		signIn(sender)
	}
	
	func signIn(sender: UIButton?) {
		sender?.setTitle("Authorizing...", forState: .Normal)
		
		oauth2.onAuthorize = { parameters in
			self.didAuthorizeWith(parameters)
		}
		oauth2.onFailure = { error in
			self.didCancelOrFail(error)
		}
		oauth2.authConfig.authorizeContext = self
		oauth2.authorize()
	}
	
	@IBAction func forgetTokens(sender: UIButton?) {
		imageView?.hidden = true
		oauth2.forgetTokens()
		resetButtons()
	}
	
	
	// MARK: - Actions
	
	func didAuthorizeWith(parameters: OAuth2JSON) {
		print("Did authorize with parameters: \(parameters)")
		
		requestUserdata { dict, error in
			if let error = error {
				print("Fetching user data failed: \(error.localizedDescription)")
				self.resetButtons()
			}
			else {
				print("Fetched user data: \(dict)")
				if let username = dict?["name"] as? String {
					self.signInEmbeddedButton?.setTitle(username, forState: .Normal)
				}
				else {
					self.signInEmbeddedButton?.setTitle("(No name found)", forState: .Normal)
				}
				if let imgURL = dict?["avatar_url"] as? String, let url = NSURL(string: imgURL) {
					self.loadAvatar(url)
				}
				self.signInSafariButton?.hidden = true
				self.forgetButton?.hidden = false
			}
		}
	}
	
	func didCancelOrFail(error: NSError?) {
		if nil != error {
			print("Authorization went wrong: \(error!.localizedDescription)")
		}
		resetButtons()
	}
	
	func resetButtons() {
		signInEmbeddedButton?.setTitle("Sign In (Embedded)", forState: .Normal)
		signInEmbeddedButton?.enabled = true
		signInSafariButton?.setTitle("Sign In (Safari)", forState: .Normal)
		signInSafariButton?.enabled = true
		signInSafariButton?.hidden = false
		forgetButton?.hidden = true
	}
	
	
	// MARK: - Requests
	
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
					print("Failed to load avatar: \(error?.localizedDescription)")
				}
			}
		}
	}
	
	/** Perform a request against the GitHub API and return decoded JSON or an NSError. */
	func requestJSON(path: String, callback: ((dict: NSDictionary?, error: NSError?) -> Void)) {
		let baseURL = NSURL(string: "https://api.github.com")!
		
		request(baseURL.URLByAppendingPathComponent(path)) { data, error in
			if let data = data {
				do {
					let dict = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? NSDictionary
					dispatch_async(dispatch_get_main_queue()) {
						callback(dict: dict, error: nil)
					}
				}
				catch let err {
					dispatch_async(dispatch_get_main_queue()) {
						callback(dict: nil, error: err as NSError)
					}
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

