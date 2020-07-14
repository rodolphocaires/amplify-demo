import Flutter
import UIKit
import WebKit

public class SwiftWebviewPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let controller = UIApplication.shared.delegate?.window??.rootViewController as! FlutterViewController

    let webviewFactory = MainWebViewFactory(controller: controller)

    registrar.register(webviewFactory, withId: "webview")
    MainCookieManager.register(with: registrar)
  }
}
