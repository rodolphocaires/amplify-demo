//
//  MainWebView.swift
//  Runner
//
//  Created by Victor Ferreira
//

import Foundation
import UIKit
import WebKit
import Flutter
import WKCookieWebView

class MainWebView: NSObject, FlutterPlatformView, WKNavigationDelegate {
    let frame: CGRect
    let viewId: Int64
    let channel: FlutterMethodChannel
    let webview: WKCookieWebView
    var cookies: [[String: String]]
    var javascriptChannelNames: NSMutableSet = NSMutableSet(array: [])
    var baseUrl: URL?
    
    init(_ frame: CGRect, viewId: Int64, channel: FlutterMethodChannel, args: Any?) {
        self.frame = frame
        self.viewId = viewId
        self.channel = channel
        
        let webview = MainWebViewBuilder()
            .withDisableInputZoom()
            .build(with: self.frame)
        self.webview = webview
        self.cookies = [[String:String]]()
        super.init()
        webview.addObserver(self, forKeyPath: "URL", context: nil)
        webview.addObserver(self, forKeyPath: "estimatedProgress", context: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(cookieChanged), name: .NSHTTPCookieManagerCookiesChanged, object: nil)
        channel.setMethodCallHandler(handler)
    }
    
    @objc private func cookieChanged(notification: NSNotification){
            var newCookies = ""

            HTTPCookieStorage.shared.cookies?.forEach({ (cookie) in
                newCookies.append("\(cookie.name)=\(cookie.value);")
            })

            self.channel.invokeMethod("onSetCookie", arguments: newCookies)
    }
    
    private func handler(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "loadUrl":
            let url = call.arguments as! String
            baseUrl = URL(string: url)
            webview.load(URLRequest(url: baseUrl!))
        case "goBack":
            self.webview.goBack()
        case "canGoBack":
            result(webview.canGoBack)
        case "evaluateJavascript":
            onEvaluateJavaScript(call: call, result: result)
        case "addJavascriptChannels":
            onAddJavaScriptChannels(call: call, result: result)
        case "removeJavascriptChannels":
            onRemoveJavaScriptChannels(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    
    func onEvaluateJavaScript(call:FlutterMethodCall, result:FlutterResult?) {
        guard let jsString = call.arguments as? String else {
            result?(FlutterError(code: "evaluateJavaScript_failed",
                                       message:"JavaScript String cannot be null",
                                       details:nil))
            return
        }

        webview.evaluateJavaScript(jsString) { (response, error) in
            guard let evaluateResult = response as? String, error == nil else {
                result?(FlutterError(code: "evaluateJavaScript_failed",
                        message:"Failed evaluating JavaScript",
                        details:nil))
                return
            }
            
            result?(String(format:"%@", evaluateResult))

        }

    }

    func onAddJavaScriptChannels(call:FlutterMethodCall, result:FlutterResult?) {
        if let channelNames = call.arguments as? [String]  {
            let channelNamesSet = NSSet(array:channelNames)
            self.javascriptChannelNames.addingObjects(from: channelNames)
            self.registerJavaScriptChannels(channelNames: channelNamesSet,
                                  controller:webview.configuration.userContentController)
            result?(nil)
        }
    }
    
    
    func onRemoveJavaScriptChannels(call:FlutterMethodCall, result:FlutterResult?) {
        webview.configuration.userContentController.removeAllUserScripts()
        javascriptChannelNames.forEach { value in
            guard let channelName = value as? String else {
                return
            }
            webview.configuration.userContentController.removeScriptMessageHandler(forName: channelName)
        }
        
        if let channelNamesToRemove:[String] = call.arguments as? [String] {
            for channelName:String in channelNamesToRemove {
                javascriptChannelNames.remove(channelName)
            }

            self.registerJavaScriptChannels(channelNames: javascriptChannelNames,
                                  controller:webview.configuration.userContentController)
            result?(nil)
        }
        
    }
    
    
    func registerJavaScriptChannels(channelNames:NSSet, controller userContentController:WKUserContentController) {
        let stringChannelNames = channelNames.allObjects.compactMap { (obj) -> String? in
            if let value = obj as? String {
                return value
            }
            
            return nil
        }
        
        stringChannelNames.forEach { (channelName) in
            let channel:JavaScriptChannel = JavaScriptChannel(methodChannel:self.channel, javaScriptChannelName:channelName)
            userContentController.add(channel, name:channelName)
            let wrapperSource = String(format:"window.%@ = webkit.messageHandlers.%@;", channelName, channelName)
            let wrapperScript = WKUserScript(source:wrapperSource,
                                       injectionTime:WKUserScriptInjectionTime.atDocumentStart,
                                    forMainFrameOnly:false)
            userContentController.addUserScript(wrapperScript)
        }
    }


    
    private func didFail(with urlString: String, _ code: Int = 501) {
        channel.invokeMethod("onHttpError", arguments: ["code":code, "url": urlString])
    }
    
    private func didStartLoading(urlString: String) {
        channel.invokeMethod("onState", arguments: ["url":urlString,"type":"startLoad"])
    }
    
    private func didFinishLoading(urlString: String) {
        channel.invokeMethod("onState", arguments: ["url":urlString,"type":"finishLoad"])
        channel.invokeMethod("onUrlChanged", arguments: ["url":urlString])
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        guard let url = webview.url else { return }
        self.didStartLoading(urlString:url.absoluteString)
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        guard let url = webview.url else { return }
        self.didStartLoading(urlString:url.absoluteString)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let observedWebView = object as? WKWebView, keyPath == "estimatedProgress", observedWebView === self.webview {
            channel.invokeMethod("onProgressChanged", arguments: ["progress":observedWebView.estimatedProgress])
        } else if let observedWebView = object as? WKWebView, keyPath == "URL", observedWebView === self.webview {
            if let url = webview.url {
                
                observedWebView.configuration.websiteDataStore.httpCookieStore.getAllCookies { (cookies) in

                    var newCookies = ""
                    
                    for cookie in cookies {
                        newCookies.append("\(cookie.name)=\(cookie.value);")
                    }
                    
                    self.channel.invokeMethod("onSetCookie", arguments: newCookies)

                }
                didFinishLoading(urlString: url.absoluteString)

            }


        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        guard let response = navigationResponse.response as? HTTPURLResponse,
            let url = navigationResponse.response.url else {
                decisionHandler(.cancel)
                return
        }
        
        if let headerFields = response.allHeaderFields as? [String: String] {
            let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url)
        
            cookies.forEach { cookie in
                print(dump(cookie))
                webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
            }
        }
        
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        if let baseUrl = baseUrl, let url = navigationAction.request.url {
            print(url)
            
            if let scheme = url.scheme, scheme == "mailto" {
                UIApplication.shared.open(url, options: [:]) { success in
                    if (!success) {
                        print("Fail to open URL")
                    }
                }
                decisionHandler(.cancel)
                return
            }
            
            let ignoredUrls = [baseUrl.host, "vars.hotjar.com"]
            if let host = url.host, !ignoredUrls.contains(host)  {
                channel.invokeMethod("onOpenExternalUrl", arguments: ["url":url.absoluteString])
                decisionHandler(.cancel)
                return
            }
        }
        
        decisionHandler(.allow)
    }
    
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        guard let url = webview.url else { return }
        self.didFinishLoading(urlString: url.absoluteString)
    }

    func webView(_ webView: WKWebView,
                 didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: Error) {
        guard let url = webview.url else { return }
        self.didFinishLoading(urlString: url.absoluteString)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let url = webview.url else { return }
        self.didFinishLoading(urlString: url.absoluteString)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        guard let url = webview.url else { return }
        self.didFinishLoading(urlString: url.absoluteString)
        self.didFail(with: url.absoluteString)
    }
    
    private func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        guard let url = webview.url else { return }
        self.didFinishLoading(urlString: url.absoluteString)
        self.didFail(with: url.absoluteString, error.code)
    }

    public func view() -> UIView {
        webview.wkNavigationDelegate = self
        
        webview.onDecidePolicyForNavigationAction = { (webView, navigationAction, decisionHandler) in
            
            if let baseUrl = self.baseUrl, let url = navigationAction.request.url {
                print(url)
                
                if let scheme = url.scheme, scheme == "mailto" {
                    UIApplication.shared.open(url, options: [:]) { success in
                        if (!success) {
                            print("Fail to open URL")
                        }
                    }
                    decisionHandler(.cancel)
                    return
                }
                
                let ignoredUrls = [baseUrl.host, "vars.hotjar.com"]
                if let host = url.host, !ignoredUrls.contains(host)  {
                    self.channel.invokeMethod("onOpenExternalUrl", arguments: ["url":url.absoluteString])
                    decisionHandler(.cancel)
                    return
                }
            }
            
            decisionHandler(.allow)
        }
        
        webview.onDecidePolicyForNavigationResponse = { (webView, navigationResponse, decisionHandler) in
            guard let response = navigationResponse.response as? HTTPURLResponse,
                let url = navigationResponse.response.url else {
                    decisionHandler(.cancel)
                    return
            }
            
            if let headerFields = response.allHeaderFields as? [String: String] {
                let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url)
            
                cookies.forEach { cookie in
                    print(dump(cookie))
                    webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
                }
            }
            
            decisionHandler(.allow)
        }
        return self.webview
    }
}
