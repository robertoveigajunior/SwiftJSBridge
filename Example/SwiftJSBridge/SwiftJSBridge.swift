//
//  SwiftJSBridge.swift
//  SwiftJavascriptBridge
//
//  Created by 王继荣 on 4/29/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import WebKit

// MARK: SwiftJSBridgeDelegate
public protocol SwiftJSBridgeDelegate {
    func swiftHandlers() -> [SwiftJSBridge.Handler]
}

// MARK: SwiftJSBridge
public class SwiftJSBridge: NSObject {
    
    // MARK: Class Methods
    public class func bridge(webView webView: WKWebView, delegate: SwiftJSBridgeDelegate) -> SwiftJSBridge {
        let swiftJSBridge = SwiftJSBridge(webView: webView)
        swiftJSBridge.delegate = delegate
        swiftJSBridge.bridge()
        
        return swiftJSBridge
    }
    
    // MARK: Properties
    public let webView: WKWebView
    public var delegate: SwiftJSBridgeDelegate?
    
    private var swiftHandlers: [String: HandlerClosure] = [:]
    
    // MARK: Private Methods
    private init(webView: WKWebView) {
        self.webView = webView
        super.init()
    }
    
    private func bridge() {
        if let handlers = delegate?.swiftHandlers() {
            handlers.forEach({ handler in
                addHandler(handler.name, closure: handler.closure)
            })
        }
    }
    
    // MARK: Public Methods
    public func addHandler(name: String, closure: HandlerClosure) {
        swiftHandlers[name] = closure
        webView.configuration.userContentController.addScriptMessageHandler(self, name: name)
    }
    
    public func removeHandler(name: String) {
        swiftHandlers.removeValueForKey(name)
        webView.configuration.userContentController.removeScriptMessageHandlerForName(name)
    }
    
    public func callJSHandler(handler: HandlerInvocation, callback: HandlerClosure?) {
        var evaluation = handler.name
//        evaluation += "(" + (handler.data ?? "") + ")"
        if let data = handler.data {
            if data is String {
                evaluation += "(\"" + (data as! String) + "\")"
            } else {
                evaluation += "(" + data.description ?? "" + ")"
                evaluation = evaluation.stringByReplacingOccurrencesOfString(String("\""), withString: "\\\"")
                
            }
        } else {
            evaluation += "()"
        }
        print(evaluation)
        webView.evaluateJavaScript(evaluation) { (response: AnyObject?, error: NSError?) in
            if error != nil {
                print("SwiftJSBridge - EvaluateJavaScript Error: " + evaluation + " - " + error.debugDescription)
            } else {
                if let response = response, let callback = callback {
                    callback(data: response)
                }
            }
        }
    }
}

extension SwiftJSBridge {
    
    public typealias HandlerClosure = (data: AnyObject?) -> Void
    
    public struct Handler {
        let name: String
        let closure: HandlerClosure
    }
    
    public struct HandlerInvocation {
        let name: String
        let data: AnyObject?
    }
}

// MARK: SwiftJSBridge - WKScriptMessageHandler
extension SwiftJSBridge: WKScriptMessageHandler {
    
    public func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        self.swiftHandlers[message.name]?(data: message.body)
    }
}
