//
//  JavascriptChannel.swift
//  Pods-Runner
//
//  Created by Victor Renan Ferreira on 03/02/20.
//

import Flutter
import WebKit

class JavaScriptChannel: NSObject, WKScriptMessageHandler {
    private var methodChannel: FlutterMethodChannel?
    private var javaScriptChannelName: String?

    init(methodChannel: FlutterMethodChannel?, javaScriptChannelName: String?) {
        super.init()
        assert(methodChannel != nil, "methodChannel must not be null.")
        assert(javaScriptChannelName != nil, "javaScriptChannelName must not be null.")
        self.methodChannel = methodChannel
        self.javaScriptChannelName = javaScriptChannelName
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        assert(methodChannel != nil, "Can't send a message to an unitialized JavaScript channel.")
        assert(javaScriptChannelName != nil, "Can't send a message to an unitialized JavaScript channel.")
        let arguments = [
            "channel": javaScriptChannelName ?? "",
            "message": "\(message.body)"
        ]
        methodChannel?.invokeMethod("javascriptChannelMessage", arguments: arguments)
    }
}
