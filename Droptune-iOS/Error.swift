//
//  ScriptMessage.swift
//  Droptune-iOS
//
//  Created by Daniel Westendorf on 12/29/19.
//  Copyright © 2019 Daniel Westendorf. All rights reserved.
//

struct Error {
    static let HTTPNotFoundError = Error(title: "Page Not Found", message: "There doesn’t seem to be anything here.")
    static let NetworkError = Error(title: "Can’t Connect", message: "Can’t connect to the server")
    static let UnknownError = Error(title: "Unknown Error", message: "An unknown error occurred.")
    
    let title: String
    let message: String
    
    init(title: String, message: String) {
        self.title = title
        self.message = message
    }
    
    init(HTTPStatusCode: Int) {
        self.title = "Server Error"
        self.message = "The server returned an HTTP \(HTTPStatusCode) response."
    }
}

