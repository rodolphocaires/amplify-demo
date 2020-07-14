package us.avenue.webview

import android.annotation.TargetApi
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.os.Build
import android.webkit.*
import io.flutter.plugin.common.MethodChannel
import java.net.URL
import java.util.*


class MainWebViewClient(val context: Context?, val channel: MethodChannel, val activity: Activity?): WebViewClient() {

    var loadedUrl: String? = null
    var cookieStore: MutableMap<String, String> = mutableMapOf()

    @TargetApi(Build.VERSION_CODES.LOLLIPOP)
    override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
        val url = request.url
        val mailTo = "mailto:"

        val baseUrl = URL(loadedUrl)
        url.host?.let {
            if (it != baseUrl.host) {
                val data = HashMap<String, Any>()
                data["url"] = url.toString()
                channel.invokeMethod("onOpenExternalUrl", data)
                return true
            }
        }

        if (url.toString().startsWith(mailTo)) {
            val intent = Intent(Intent.ACTION_SENDTO, request.url)
            context?.startActivity(intent)
            return true
        }

        return super.shouldOverrideUrlLoading(view, request)
    }

    @TargetApi(Build.VERSION_CODES.LOLLIPOP)
    override fun onReceivedHttpError(view: WebView?, request: WebResourceRequest?, errorResponse: WebResourceResponse?) {
        super.onReceivedHttpError(view, request, errorResponse)
        if(request != null && errorResponse != null) {
            val data = HashMap<String, Any>()
            data["url"] = request.url.toString()
            data["code"] = errorResponse.statusCode.toString()
            channel.invokeMethod("onHttpError", data)
        }
    }

    override fun onPageStarted(view: WebView?, url: String?, favicon: Bitmap?) {
        super.onPageStarted(view, url, favicon)
        val data = HashMap<String, Any>()
        if (url != null) {
            data["url"] = url
            data["type"] = "startLoad"
            channel.invokeMethod("onState", data)
        }
    }

    override fun doUpdateVisitedHistory(view: WebView?, url: String?, isReload: Boolean) {
        super.doUpdateVisitedHistory(view, url, isReload)
        if (url!= null) {
            val data = HashMap<String, Any>()
            data["url"] = url
            channel.invokeMethod("onUrlChanged", data)
            data["type"] = "finishLoad"
            channel.invokeMethod("onState", data)

            val urlRequest = URL(url)
            val urlLoaded = URL(loadedUrl)
            if (urlRequest.host == urlLoaded.host) {
                val cookieStr: String? = CookieManager.getInstance().getCookie(url)
                activity?.runOnUiThread {
                    channel.invokeMethod("onSetCookie", cookieStr)
                }
            }
        }
    }

    @TargetApi(Build.VERSION_CODES.M)
    override fun onReceivedError(view: WebView?, request: WebResourceRequest?, error: WebResourceError?) {
        super.onReceivedError(view, request, error)
        if(request != null && error != null) {
            val data = HashMap<String, Any>()
            data["url"] = request.url.toString()
            data["code"] = error.errorCode
            channel.invokeMethod("onHttpError", data)
        }
    }

    override fun onReceivedError(view: WebView?, errorCode: Int, description: String?, failingUrl: String?) {
        super.onReceivedError(view, errorCode, description, failingUrl)
        if(failingUrl != null) {
            val data = HashMap<String, Any>()
            data["url"] = failingUrl
            data["code"] = errorCode
            channel.invokeMethod("onHttpError", data)
        }
    }

    override fun onPageFinished(view: WebView, url: String) {
        super.onPageFinished(view, url)
        val data = HashMap<String, Any>()
        data["url"] = url

        channel.invokeMethod("onUrlChanged", data)

        data["type"] = "finishLoad"
        channel.invokeMethod("onState", data)
    }

}