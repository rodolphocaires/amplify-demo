package us.avenue.webview;

import android.os.Handler;
import android.os.Looper;
import android.webkit.JavascriptInterface;

import java.util.HashMap;

import io.flutter.plugin.common.MethodChannel;

class JavaScriptChannel {
    private final MethodChannel methodChannel;
    private final String javaScriptChannelName;
    private final Handler platformThreadHandler;

    JavaScriptChannel(
            MethodChannel methodChannel, String javaScriptChannelName, Handler platformThreadHandler) {
        this.methodChannel = methodChannel;
        this.javaScriptChannelName = javaScriptChannelName;
        this.platformThreadHandler = platformThreadHandler;
    }

    @JavascriptInterface
    public void postMessage(final String message) {
        Runnable postMessageRunnable =
                new Runnable() {
                    @Override
                    public void run() {
                        HashMap<String, String> arguments = new HashMap<>();
                        arguments.put("channel", javaScriptChannelName);
                        arguments.put("message", message);
                        methodChannel.invokeMethod("javascriptChannelMessage", arguments);
                    }
                };
        if (platformThreadHandler.getLooper() == Looper.myLooper()) {
            postMessageRunnable.run();
        } else {
            platformThreadHandler.post(postMessageRunnable);
        }
    }
}