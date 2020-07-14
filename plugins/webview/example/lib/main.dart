import 'package:flutter/material.dart';
import 'package:webview/main_webview_plugin.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  WebViewController controller;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            controller.evaluateJavascript("window.changeLanguage('en')");
          },
        ),
        body: Column(
          children: <Widget>[
            Expanded(
                child: WillPopScope(
              onWillPop: () {
                controller.goBack();
                return Future.value(true);
              },
              child: MainWebView(onWebViewCreated: (controller) {
                this.controller = controller;
                controller.onProgressChanged.listen((data) {
                  print("progress: $data");
                });
                controller.onUrlChanged.listen((data) {
                  print("url: $data");
                });
                controller.onOpenExternalUrl.listen((data) {
                  print("url: $data");
                });
                controller.onSetCookie.listen((data) {
                  print("cookie Value: $data");
                });
                controller.loadUrl('https://pit.avenue.us');
              }),
            ))
          ],
        ),
      ),
    );
  }
}
