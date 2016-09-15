//
//  OAuth2RetryHandler.swift
//  OAuth2PodApp
//
//  Created by Pascal Pfiffner on 15.09.16.
//  Copyright © 2016 Ossus. All rights reserved.
//

import Foundation
import p2_OAuth2
import Alamofire


/**
An adapter for Alamofire. Set up your OAuth2 instance as usual, without forgetting to implement `handleRedirectURL()`, instantiate **one**
`SessionManager` and use this class as the manager's `adapter` and `retrier`, like so:

    let oauth2 = OAuth2CodeGrant(settings: [...])
    oauth2.authConfig.authorizeEmbedded = true    // if you want embedded
    oauth2.authConfig.authorizeContext = <# your UIViewController / NSWindow #>

    let sessionManager = SessionManager()
    let retrier = OAuth2RetryHandler(oauth2: oauth2)
    sessionManager.adapter = retrier
    sessionManager.retrier = retrier
    self.alamofireManager = sessionManager

    sessionManager.request("https://api.github.com/user").validate().responseJSON { response in
        debugPrint(response)
    }
*/
class OAuth2RetryHandler: RequestRetrier, RequestAdapter {
	
	let loader: OAuth2DataLoader
	
	init(oauth2: OAuth2) {
		loader = OAuth2DataLoader(oauth2: oauth2)
	}
	
	/// Intercept 401 and do an OAuth2 authorization.
	public func should(_ manager: SessionManager, retry request: Request, with error: Error, completion: @escaping RequestRetryCompletion) {
		if let response = request.task?.response as? HTTPURLResponse, 401 == response.statusCode, let req = request.request {
			var dataRequest = OAuth2DataRequest(request: req, callback: { _ in })
			dataRequest.context = completion
			loader.enqueue(request: dataRequest)
			loader.attemptToAuthorize() { authParams, error in
				self.loader.dequeueAndApply() { req in
					if let comp = req.context as? RequestRetryCompletion {
						comp(nil != authParams, 0.0)
					}
				}
			}
		}
		else {
			completion(false, 0.0)   // not a 401, not our problem
		}
	}
	
	/// Sign the request with the access token.
	public func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
		guard nil != loader.oauth2.accessToken else {
			return urlRequest
		}
		return urlRequest.signed(with: loader.oauth2)
	}
}

