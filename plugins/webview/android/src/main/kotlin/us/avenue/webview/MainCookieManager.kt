package us.avenue.webview

import android.os.Build
import android.os.Build.VERSION_CODES
import android.webkit.CookieManager
import android.webkit.ValueCallback
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel


class MainCookieManager(messenger: BinaryMessenger) : MethodChannel.MethodCallHandler {
    private var methodChannel: MethodChannel

    init {
        methodChannel = MethodChannel(messenger, "cookie_manager")
        methodChannel.setMethodCallHandler(this)
    }

    fun dispose() {
        methodChannel.setMethodCallHandler(null)
    }

    private fun clearCookies(result: MethodChannel.Result) {
        val cookieManager: CookieManager = CookieManager.getInstance()
        val hasCookies: Boolean = cookieManager.hasCookies()
        if (Build.VERSION.SDK_INT >= VERSION_CODES.LOLLIPOP) {
            cookieManager.removeAllCookies { result.success(hasCookies) }
        } else {
            cookieManager.removeAllCookie()
            result.success(hasCookies)
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "clearCookies" -> clearCookies(result)
            else -> result.notImplemented()
        }
    }
}