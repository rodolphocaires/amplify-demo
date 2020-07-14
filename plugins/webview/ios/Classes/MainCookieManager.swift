//
//  MainCookieManager.swift
//  Pods-Runner
//
//  Created by Victor Ferreira on 08/01/20.
//

import Foundation
import Flutter
import WebKit

class MainCookieManager : NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = MainCookieManager();
        
        let channel = FlutterMethodChannel(
            name: "cookie_manager",
            binaryMessenger: registrar.messenger()
        )
        
        registrar.addMethodCallDelegate(instance, channel: channel)

    }
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if (call.method == "clearCookies") {
            clearCookies(result: result)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
    
    func clearCookies(result: @escaping FlutterResult) {
        let websiteDataTypes:Set = [WKWebsiteDataTypeCookies]
        let dataStore = WKWebsiteDataStore.default()
        
        dataStore.fetchDataRecords(ofTypes: websiteDataTypes) { (cookies) in
            let hasCookies = cookies.count > 0;
            dataStore.removeData(ofTypes: websiteDataTypes, for: cookies) {
                result(hasCookies)
            }
        }
    }
    
    
    
    
}
