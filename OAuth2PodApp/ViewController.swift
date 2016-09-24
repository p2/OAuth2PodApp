//
//  ViewController.swift
//  OAuth2PodApp
//
//  Created by Pascal Pfiffner on 7/6/15.
//  Copyright (c) 2015 Ossus. All rights reserved.
//

import UIKit
import p2_OAuth2
import Alamofire


class ViewController: UIViewController {
	
	fileprivate var alamofireManager: SessionManager?
	
	var loader: OAuth2DataLoader?
	
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
	@IBOutlet var signInAutoButton: UIButton?
	@IBOutlet var forgetButton: UIButton?
	
	
	@IBAction func signInEmbedded(_ sender: UIButton?) {
		if oauth2.isAuthorizing {
			oauth2.abortAuthorization()
			return
		}
		
		sender?.setTitle("Authorizing...", for: UIControlState.normal)
		
		oauth2.authConfig.authorizeEmbedded = true
		oauth2.authConfig.authorizeContext = self
		let loader = OAuth2DataLoader(oauth2: oauth2)
		self.loader = loader
		
		loader.perform(request: userDataRequest) { response in
			do {
				let json = try response.responseJSON()
				self.didGetUserdata(dict: json, loader: loader)
			}
			catch let error {
				self.didCancelOrFail(error)
			}
		}
	}
	
	@IBAction func signInSafari(_ sender: UIButton?) {
		if oauth2.isAuthorizing {
			oauth2.abortAuthorization()
			return
		}
		
		sender?.setTitle("Authorizing...", for: UIControlState.normal)
	
		oauth2.authConfig.authorizeEmbedded = false		// the default
		let loader = OAuth2DataLoader(oauth2: oauth2)
		self.loader = loader
		
		loader.perform(request: userDataRequest) { response in
			do {
				let json = try response.responseJSON()
				self.didGetUserdata(dict: json, loader: loader)
			}
			catch let error {
				self.didCancelOrFail(error)
			}
		}
	}
	
	/**
	This method relies fully on Alamofire and OAuth2RequestRetrier.
	*/
	@IBAction func autoSignIn(_ sender: UIButton?) {
		sender?.setTitle("Loading...", for: UIControlState.normal)
		let sessionManager = SessionManager()
		let retrier = OAuth2RetryHandler(oauth2: oauth2)
		sessionManager.adapter = retrier
		sessionManager.retrier = retrier
		alamofireManager = sessionManager
		
		sessionManager.request("https://api.github.com/user").validate().responseJSON { response in
			debugPrint(response)
			if let dict = response.result.value as? [String: Any] {
				self.didGetUserdata(dict: dict, loader: nil)
			}
			else {
				self.didCancelOrFail(OAuth2Error.generic("\(response)"))
			}
		}
		sessionManager.request("https://api.github.com/user/repos").validate().responseJSON { response in
			debugPrint(response)
		}
	}
	
	@IBAction func forgetTokens(_ sender: UIButton?) {
		imageView?.isHidden = true
		oauth2.forgetTokens()
		resetButtons()
	}
	
	
	// MARK: - Actions
	
	var userDataRequest: URLRequest {
		var request = URLRequest(url: URL(string: "https://api.github.com/user")!)
		request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
		return request
			}
	
	func didGetUserdata(dict: [String: Any], loader: OAuth2DataLoader?) {
		DispatchQueue.main.async {
			if let username = dict["name"] as? String {
				self.signInEmbeddedButton?.setTitle(username, for: UIControlState())
				}
				else {
				self.signInEmbeddedButton?.setTitle("(No name found)", for: UIControlState())
				}
			if let imgURL = dict["avatar_url"] as? String, let url = URL(string: imgURL) {
				self.loadAvatar(from: url, with: loader)
			}
			self.signInSafariButton?.isHidden = true
			self.signInAutoButton?.isHidden = true
			self.forgetButton?.isHidden = false
		}
	}
	
	func didCancelOrFail(_ error: Error?) {
		DispatchQueue.main.async {
		if let error = error {
			print("Authorization went wrong: \(error)")
		}
			self.resetButtons()
		}
	}
	
	func resetButtons() {
		signInEmbeddedButton?.setTitle("Sign In (Embedded)", for: UIControlState())
		signInEmbeddedButton?.isEnabled = true
		signInSafariButton?.setTitle("Sign In (Safari)", for: UIControlState())
		signInSafariButton?.isEnabled = true
		signInSafariButton?.isHidden = false
		signInAutoButton?.setTitle("Auto Sign In", for: UIControlState())
		signInAutoButton?.isEnabled = true
		signInAutoButton?.isHidden = false
		forgetButton?.isHidden = true
	}
	
	
	// MARK: - Avatar
	
	func loadAvatar(from url: URL, with loader: OAuth2DataLoader?) {
		if let loader = loader {
			loader.perform(request: URLRequest(url: url)) { response in
				do {
					let data = try response.responseData()
					DispatchQueue.main.async {
						self.imageView?.image = UIImage(data: data)
						self.imageView?.isHidden = false
					}
				}
				catch let error {
					print("Failed to load avatar: \(error)")
					}
				}
			}
			else {
			alamofireManager?.request(url).validate().responseData() { response in
				if let data = response.result.value {
					self.imageView?.image = UIImage(data: data)
					self.imageView?.isHidden = false
			}
				else {
					print("Failed to load avatar: \(response)")
		}
	}
		}
	}
}

