//
//  ScriptMessage.swift
//  Droptune-iOS
//
//  Created by Daniel Westendorf on 12/29/19.
//  Copyright © 2019 Daniel Westendorf. All rights reserved.
//

import UIKit
import WebKit
import Turbolinks
import SafariServices

class ApplicationController: UINavigationController {
    fileprivate let url = URL(string: "https://dwlocal.ngrok.io")!
    fileprivate let authPaths = [
        "/users/auth/twitter", "/users/auth/spotify"
    ]
    fileprivate let webViewProcessPool = WKProcessPool()

    fileprivate var application: UIApplication {
        return UIApplication.shared
    }

    fileprivate lazy var webViewConfiguration: WKWebViewConfiguration = {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(self, name: "Droptune")
        configuration.processPool = self.webViewProcessPool
        // Get version and build
        let version = Bundle.main.infoDictionary!["CFBundleShortVersionString"]
        let build = Bundle.main.infoDictionary!["CFBundleVersion"]
       configuration.applicationNameForUserAgent = "Droptune - MobileApp iOS - version::\(version ?? "Unknown") Build(\(build ?? "Unknown"))"
        
        return configuration
    }()

    fileprivate lazy var session: Session = {
        let session = Session(webViewConfiguration: self.webViewConfiguration)
        session.delegate = self
        return session
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Switching this to false will prevent content from sitting beneath scrollbar
        navigationBar.isTranslucent = true
        
        presentVisitableForSession(session, url: url)
    }

    fileprivate func presentVisitableForSession(_ session: Session, url: URL, action: Action = .Advance) {
        let visitable = ViewController(url: url)

        if action == .Advance {
            pushViewController(visitable, animated: true)
        } else if action == .Replace {
            popViewController(animated: false)
            pushViewController(visitable, animated: false)
        }
        
        session.visit(visitable)
    }

    fileprivate func presentAuthenticationController(url: URL) {
        let authenticationController = AuthenticationController()
        authenticationController.delegate = self
        authenticationController.webViewConfiguration = webViewConfiguration
        authenticationController.url = url
        authenticationController.title = "Sign in"

        let authNavigationController = UINavigationController(rootViewController: authenticationController)
        present(authNavigationController, animated: true, completion: nil)
    }
}

extension ApplicationController: SessionDelegate {
    func session(_ session: Session, didProposeVisitToURL URL: Foundation.URL, withAction action: Action) {
        NSLog("Attempted visit to %@", URL.absoluteString)
        
        let authRequest = authPaths.contains { (path) -> Bool in
            return URL.path == path
        }
        
        if authRequest {
            presentAuthenticationController(url: URL)
        } else {
            presentVisitableForSession(session, url: URL, action: action)
        }
    }
    
    func session(_ session: Session, didFailRequestForVisitable visitable: Visitable, withError error: NSError) {
        NSLog("ERROR: %@", error)
        guard let viewController = visitable as? ViewController, let errorCode = ErrorCode(rawValue: error.code) else { return }

        switch errorCode {
        case .httpFailure:
            let statusCode = error.userInfo["statusCode"] as! Int
            switch statusCode {
            case 404:
                viewController.presentError(.HTTPNotFoundError)
            default:
                viewController.presentError(Error(HTTPStatusCode: statusCode))
            }
        case .networkFailure:
            viewController.presentError(.NetworkError)
        }
    }
    
    func sessionDidStartRequest(_ session: Session) {
    }

    func sessionDidFinishRequest(_ session: Session) {
    }
    
    func session(_ session: Session, openExternalURL URL: URL) {
        let safariViewController = SFSafariViewController.init(url: URL)
        present(safariViewController, animated: true, completion: nil)
    }
}

extension ApplicationController: AuthenticationControllerDelegate {
    func authenticationControllerDidAuthenticate(_ authenticationController: AuthenticationController) {
        session.reload()
        dismiss(animated: true, completion: nil)
    }
}

extension ApplicationController: WKScriptMessageHandler {
    func handleScriptMessage(message: ScriptMessage) {
        switch message.name {
        case .ErrorRaised:
            let error = message.data["error"] as? String
            NSLog("JavaScript error: %@", error ?? "<unknown error>")
            
            if let alert = message.data["alert"] as? String {
                showAlert(message: alert)
            }
        }
    }
    
    func showAlert(message: String) {
        let alertController = UIAlertController(title: "Droptune", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let message = ScriptMessage.parse(message) else { return }
        
        handleScriptMessage(message: message)
    }
}
