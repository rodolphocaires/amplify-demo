//
//  MainWebviewBuilder.swift
//  Runner
//
//  Created by Victor Ferreira

import Foundation
import UIKit
import WebKit
import WKCookieWebView

class MainWebViewBuilder {
    
    init(userContentController: WKUserContentController = WKUserContentController(),
         conf:WKWebViewConfiguration = WKWebViewConfiguration(),
         scrollViewDelegate:ScrollViewDelegate = ScrollViewDelegate()) {
        self.userContentController = userContentController
        self.conf = conf
        self.scrollViewDelegate = scrollViewDelegate
    }
    
    private let userContentController: WKUserContentController
    private let conf:WKWebViewConfiguration
    private let scrollViewDelegate: ScrollViewDelegate
    private var webViewDelegate: WKNavigationDelegate?

    func withNetworkDelegate( _ delegate: WKNavigationDelegate) -> MainWebViewBuilder {
        webViewDelegate = delegate
        return self
    }
    
    func withMessageHandler( _ messageHandler: WKScriptMessageHandler) -> MainWebViewBuilder {
        userContentController.add(messageHandler, name: "native")
        return self
    }
    
    @discardableResult
    func withDisableInputZoom() -> MainWebViewBuilder {
        let source: String = "var meta = document.createElement('meta');" +
            "meta.name = 'viewport';" +
            "meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';" + "var head = document.getElementsByTagName('head')[0];" +
        "head.appendChild(meta);";

        let script: WKUserScript = WKUserScript(source: source,
                                                injectionTime: .atDocumentEnd,
                                                forMainFrameOnly: true)
        userContentController.addUserScript(script)
        conf.userContentController = userContentController
        return self
    }
    
    func build(with frame: CGRect) -> WKCookieWebView {
        let webview = WKCookieWebView(frame: frame, configurationBlock: { (config) in
            config.userContentController = self.userContentController
        })
        webview.scrollView.delegate = scrollViewDelegate
        webview.navigationDelegate = webViewDelegate
        webview.scrollView.contentInsetAdjustmentBehavior = .never
        
        if #available(iOS 13.0, *) {
            webview.scrollView.automaticallyAdjustsScrollIndicatorInsets = false
        }
        return webview
    }

}
