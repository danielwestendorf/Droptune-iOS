//
//  ScriptMessage.swift
//  Droptune-iOS
//
//  Created by Daniel Westendorf on 12/29/19.
//  Copyright © 2019 Daniel Westendorf. All rights reserved.
//

import WebKit

enum ScriptMessageName: String {
    case ErrorRaised = "errorRaised"
}

class ScriptMessage {
    let name: ScriptMessageName
    let data: [String: AnyObject]
    
    init(name: ScriptMessageName, data: [String: AnyObject]) {
        self.name = name
        self.data = data
    }
    
    static func parse(_ message: WKScriptMessage) -> ScriptMessage? {
        guard let body = message.body as? [String: AnyObject],
            let rawName = body["name"] as? String, let name = ScriptMessageName(rawValue: rawName),
            let data = body["data"] as? [String: AnyObject] else { return nil }
        return ScriptMessage(name: name, data: data)
    }
}
