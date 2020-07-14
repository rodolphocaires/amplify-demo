package us.avenue.webview

import android.annotation.SuppressLint
import android.annotation.TargetApi
import android.app.Activity
import android.content.Context
import android.hardware.display.DisplayManager
import android.os.Build
import android.os.Handler
import android.view.View
import android.webkit.CookieManager
import android.webkit.WebView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import java.util.*


class MainWebPlatformView(private val context: Context?,
                          private val activity: Activity?,
                          private val containerView: View?,
                          messenger: BinaryMessenger,
                          channelId: String) : MethodChannel.MethodCallHandler, PlatformView {


    var webView: InputAwareWebView
    val channel: MethodChannel
    var webViewClient: MainWebViewClient? = null
    private var platformThreadHandler: Handler? = null

    init {
        channel = MethodChannel(messenger, channelId)
        channel.setMethodCallHandler(this)

        webView = getWebView(activity, context, channel)
    }

    @TargetApi(Build.VERSION_CODES.LOLLIPOP)
    @SuppressLint("SetJavaScriptEnabled")
    private fun getWebView(activity: Activity?, context: Context?, channel: MethodChannel): InputAwareWebView {

        val displayListenerProxy = DisplayListenerProxy()
        val displayManager = context?.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
        displayListenerProxy.onPreWebViewInitialization(displayManager)
        webView = InputAwareWebView(context, containerView);
        displayListenerProxy.onPostWebViewInitialization(displayManager)
        platformThreadHandler = Handler(context.mainLooper);
        CookieManager.getInstance().setAcceptCookie(true)
        CookieManager.getInstance().setAcceptThirdPartyCookies(webView, true)
        WebView.setWebContentsDebuggingEnabled(true);
        webViewClient = MainWebViewClient(context, channel, activity)

        webView.webViewClient = webViewClient
        webView.isFocusableInTouchMode = true
        webView.settings.javaScriptEnabled = true
        webView.settings.domStorageEnabled = true
        webView.settings.allowFileAccess = true
        webView.settings.allowFileAccessFromFileURLs = true
        webView.settings.allowUniversalAccessFromFileURLs = true

        return webView
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "loadUrl" -> loadUrl(call, result)
            "goBack" -> back(result)
            "canGoBack" -> canGoBack(result)
            "clearCookies" -> clearCookie(result)
            "evaluateJavascript" -> evaluateJavaScript(call, result)
            "addJavascriptChannels" -> addJavaScriptChannels(call, result)
            "removeJavascriptChannels" -> removeJavaScriptChannels(call, result)
            else -> result.notImplemented()
        }
    }

    @TargetApi(Build.VERSION_CODES.KITKAT)
    private fun evaluateJavaScript(call: MethodCall, result: MethodChannel.Result) {
        val jsString = call.arguments as String
        webView.evaluateJavascript(
                jsString
        ) { value -> result.success(value) }
    }


    private fun addJavaScriptChannels(methodCall: MethodCall, result: MethodChannel.Result) {
        val channelNames = methodCall.arguments as List<String>
        registerJavaScriptChannelNames(channelNames)
        result.success(null)
    }

    private fun removeJavaScriptChannels(methodCall: MethodCall, result: MethodChannel.Result) {
        val channelNames = methodCall.arguments as List<String>
        for (channelName in channelNames) {
            webView.removeJavascriptInterface(channelName)
        }
        result.success(null)
    }

    private fun registerJavaScriptChannelNames(channelNames: List<String>) {
        for (channelName in channelNames) {
            webView.addJavascriptInterface(
                    JavaScriptChannel(channel, channelName, platformThreadHandler), channelName)
        }
    }

    @TargetApi(Build.VERSION_CODES.LOLLIPOP)
    private fun clearCookie(result: MethodChannel.Result) {
        val cookieManager = CookieManager.getInstance()
        val hasCookies = cookieManager.hasCookies()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            cookieManager.removeAllCookies { result.success(hasCookies) }
        } else {
            cookieManager.removeAllCookie()
            result.success(hasCookies)
        }
    }

    fun loadUrl(call: MethodCall, result: MethodChannel.Result) {
        val url = call.arguments as String
        webViewClient?.loadedUrl = url
        webView.loadUrl(url)
        result.success(null)
    }

    fun back(result: MethodChannel.Result) {
        if (webView.canGoBack()) {
            webView.goBack()
        }
        result.success(null)
    }

    fun canGoBack(result: MethodChannel.Result) {
        result.success(webView.canGoBack())
    }

    override fun dispose() {
        channel.setMethodCallHandler(null)
        webView.dispose()
        webView.destroy()
    }

    override fun getView(): View {
        return webView
    }

    fun onProgressChanged(progress: Double) {
        val args = HashMap<String, Double>()
        args["progress"] = progress
        channel.invokeMethod("onProgressChanged", args)
    }

    override fun onInputConnectionUnlocked() {
        webView.unlockInputConnection()
    }

    override fun onInputConnectionLocked() {
        webView.lockInputConnection()
    }

    override fun onFlutterViewAttached(flutterView: View) {
        webView.setContainerView(flutterView);
    }

    override fun onFlutterViewDetached() {
        webView.setContainerView(null);
    }

}