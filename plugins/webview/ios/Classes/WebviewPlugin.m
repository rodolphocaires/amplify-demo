#import "WebviewPlugin.h"
#import <webview/webview-Swift.h>

@implementation WebviewPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftWebviewPlugin registerWithRegistrar:registrar];
}
@end
