package us.avenue.webview

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.view.View
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.PluginRegistry.Registrar

class WebviewPlugin(activity: Activity?, context: Context?, messenger: BinaryMessenger, containerView: View?): FlutterPlugin, ActivityAware, PluginRegistry.ActivityResultListener {

  private var flutterCookieManager: MainCookieManager? = null
  var webManager: MainWebViewManager

  init {
    flutterCookieManager = MainCookieManager(messenger)
    webManager = MainWebViewManager(activity, context, messenger, containerView)
  }

  override fun onActivityResult(requestCode: Int, resultCode: Int, intent: Intent?): Boolean {
    return webManager.resultHandler.handleResult(requestCode, resultCode, intent)
  }

  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val instance = WebviewPlugin(registrar.activity(), registrar.activeContext(), registrar.messenger(), registrar.view())
      registrar.platformViewRegistry()
              .registerViewFactory("webview", instance.webManager)
      registrar.addActivityResultListener(instance)
    }
  }

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {

    val messenger: BinaryMessenger = binding.flutterEngine.dartExecutor
    webManager = MainWebViewManager(null, binding.applicationContext, messenger, null)
    binding
            .flutterEngine
            .platformViewsController
            .registry
            .registerViewFactory(
                    "webview", webManager)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    if (flutterCookieManager == null) {
      return;
    }

    flutterCookieManager?.dispose();
    flutterCookieManager = null;
  }

  override fun onDetachedFromActivity() {

  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    onAttachedToActivity(binding) //To change body of created functions use File | Settings | File Templates.
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    webManager.activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity() //To change body of created functions use File | Settings | File Templates.
  }

}
