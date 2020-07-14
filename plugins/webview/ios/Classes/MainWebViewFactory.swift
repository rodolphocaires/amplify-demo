//
//  WebviewFactory.swift
//  Runner
//
//  Created by Victor Ferreira
//

import Foundation
import Flutter
import WebKit

class MainWebViewFactory: NSObject, FlutterPlatformViewFactory {
    let controller: FlutterViewController
    var webview: WKWebView?
    
    init(controller: FlutterViewController) {
        self.controller = controller
    }
    
    public func create( withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?
    ) -> FlutterPlatformView {
        let channel = FlutterMethodChannel(
            name: "webview" + String(viewId),
            binaryMessenger: controller.binaryMessenger
        )

        return MainWebView(frame, viewId: viewId, channel: channel, args: args)
    }
    
}
