package com.example.amplify

import io.flutter.app.FlutterApplication
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.PluginRegistry.PluginRegistrantCallback
import us.avenue.webview.WebviewPlugin

class Application : FlutterApplication(), PluginRegistrantCallback {
    override fun registerWith(registry: PluginRegistry) {
        WebviewPlugin.registerWith(registry.registrarFor("us.avenue.webview.WebviewPlugin"))
    }
}