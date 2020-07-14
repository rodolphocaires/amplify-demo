import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef void WebViewCreatedCallback(WebViewController controller);
typedef void WebViewNavigationChange(String newUrl);
typedef void WebViewMessagePosted(Map<String, dynamic> message);

class MainWebView extends StatefulWidget {

  const MainWebView({
    this.onWebViewCreated,
    this.onWebViewMessagePosted,
    this.onWebViewNavigationChange,
    this.javascriptChannels,
  });

  final WebViewCreatedCallback onWebViewCreated;
  final WebViewNavigationChange onWebViewNavigationChange;
  final WebViewMessagePosted onWebViewMessagePosted;
  final Set<JavascriptChannel> javascriptChannels;

  static const MethodChannel _cookieManagerChannel = MethodChannel('cookie_manager');

  @override
  State<StatefulWidget> createState() => MainWebViewState();

  static Future<bool> clearCookies() {
    return _cookieManagerChannel
        .invokeMethod<bool>('clearCookies')
        .then<bool>((dynamic result) => result);
  }

}

class JavascriptMessage {
  const JavascriptMessage(this.message) : assert(message != null);
  final String message;
}

typedef void JavascriptMessageHandler(JavascriptMessage message);

final RegExp _validChannelNames = RegExp('^[a-zA-Z_][a-zA-Z0-9_]*\$');

class JavascriptChannel {

  JavascriptChannel({
    @required this.name,
    @required this.onMessageReceived,
  })  : assert(name != null),
        assert(onMessageReceived != null),
        assert(_validChannelNames.hasMatch(name));

  final String name;

  final JavascriptMessageHandler onMessageReceived;
}


class MainWebViewState extends State<MainWebView> {

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {

      return AndroidView(
        viewType: 'webview',
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: 'webview',
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    }
    return Text(
        '$defaultTargetPlatform is not yet supported by the map view plugin');
  }

  void _onPlatformViewCreated(int id) {
    if (widget.onWebViewCreated == null) {
      return;
    }
    widget.onWebViewCreated(new WebViewController(widget, id, widget.onWebViewNavigationChange, widget.onWebViewMessagePosted));
  }

}

class CookieManager {

  factory CookieManager() {
    return _instance ??= CookieManager._();
  }

  CookieManager._();

  static CookieManager _instance;

  Future<bool> clearCookies() => MainWebView.clearCookies();
}

class WebViewController {

  WebViewController(MainWebView _widget, int id, this.onWebViewNavigationChange, this.onWebViewMessagePosted ) {
    this._channel = new MethodChannel('webview$id');
    this._channel.setMethodCallHandler(_handleMessages);
    _updateJavascriptChannelsFromSet(_widget.javascriptChannels);
  }
  final _onUrlChanged = StreamController<String>.broadcast();
  final _onProgressChanged = StreamController<double>.broadcast();
  final _onHttpError = StreamController<MainWebViewHttpError>.broadcast();
  final _onOpenExternalUrl = StreamController<String>.broadcast();
  final _onStateChanged = StreamController<MainWebViewStateChanged>.broadcast();
  final _onSetCookie = StreamController<String>.broadcast();

  Stream<double> get onProgressChanged => _onProgressChanged.stream;
  Stream<String> get onUrlChanged => _onUrlChanged.stream;
  Stream<MainWebViewHttpError> get onHttpError => _onHttpError.stream;
  Stream<MainWebViewStateChanged> get onStateChanged => _onStateChanged.stream;
  Stream<String> get onSetCookie => _onSetCookie.stream;
  Stream<String> get onOpenExternalUrl => _onOpenExternalUrl.stream;

  Map<String, JavascriptChannel> _javascriptChannels = Map<String, JavascriptChannel>();

  final WebViewNavigationChange onWebViewNavigationChange;
  final WebViewMessagePosted onWebViewMessagePosted;

  MethodChannel _channel;

  Future<void> loadUrl(String url) async {
    return _channel.invokeMethod('loadUrl', url);
  }

  Future<void> goBack() async => await _channel.invokeMethod('goBack');

  Future<bool> canGoBack() async => await _channel.invokeMethod('canGoBack');

  Future<String> evaluateJavascript(String javascriptString) {
    return _channel.invokeMethod<String>(
        'evaluateJavascript', javascriptString);
  }

  void _updateJavascriptChannelsFromSet(Set<JavascriptChannel> channels) async {

    _javascriptChannels.clear();
    if (channels == null) {
      return;
    }
    Set<String> _channelsNames = Set();
    for (JavascriptChannel channel in channels) {
      _javascriptChannels[channel.name] = channel;
      _channelsNames.add(channel.name);
    }

    addJavascriptChannels(_channelsNames);
  }

  Future<void> addJavascriptChannels(Set<String> javascriptChannelNames) {
    return _channel.invokeMethod<void>(
        'addJavascriptChannels', javascriptChannelNames.toList());
  }

  Future<void> removeJavascriptChannels(Set<String> javascriptChannelNames) {
    return _channel.invokeMethod<void>(
        'removeJavascriptChannels', javascriptChannelNames.toList());
  }

  Future<Null> _handleMessages(MethodCall call) async {
    switch (call.method) {
      case 'onUrlChanged':
        _onUrlChanged.add(call.arguments['url']);
        break;
      case 'onProgressChanged':
        _onProgressChanged.add(call.arguments['progress']);
        break;
      case 'onOpenExternalUrl':
        _onOpenExternalUrl.add(call.arguments['url']);
        break;
      case 'onState':
        _onStateChanged.add(
          MainWebViewStateChanged.fromMap(
            Map<String, dynamic>.from(call.arguments),
          ),
        );
        break;
      case 'onHttpError':
        _onHttpError.add(
            MainWebViewHttpError(code: call.arguments['code'], url: call.arguments['url']));
        break;
      case 'onSetCookie':
        _onSetCookie.add(call.arguments);
        break;
      case 'javascriptChannelMessage':
        _handleJavascriptChannelMessage(call.arguments['channel'], call.arguments['message']);
        break;
    }

  }

  void _handleJavascriptChannelMessage(
      final String channelName, final String message) {
    _javascriptChannels[channelName].onMessageReceived(JavascriptMessage(message));
  }

  Future<String> evalJavascript(String code) async {
    final res = await _channel.invokeMethod('eval', {'code': code});
    return res;
  }


  void dispose() {
    _onUrlChanged.close();
    _onProgressChanged.close();
    _onHttpError.close();
    _onOpenExternalUrl.close();
    _onStateChanged.close();
    _javascriptChannels.clear();
    _onSetCookie.close();
  }

}

class MainWebViewHttpError {
  const MainWebViewHttpError({this.code, this.url});

  final String url;
  final String code;
}

enum WebViewState { startLoad, finishLoad }

class MainWebViewStateChanged {
  MainWebViewStateChanged(this.type, this.url);

  factory MainWebViewStateChanged.fromMap(Map<String, dynamic> map) {
    WebViewState t;
    switch (map['type']) {
      case 'startLoad':
        t = WebViewState.startLoad;
        break;
      case 'finishLoad':
        t = WebViewState.finishLoad;
        break;
    }
    return MainWebViewStateChanged(t, map['url']);
  }

  final WebViewState type;
  final String url;
}