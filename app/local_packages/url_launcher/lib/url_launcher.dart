import 'package:flutter/services.dart';

enum LaunchMode {
  platformDefault,
  inAppWebView,
  inAppBrowserView,
  externalApplication,
  externalNonBrowserApplication,
}

const MethodChannel _channel = MethodChannel('apelmat.local/url_launcher');

Future<bool> canLaunchUrl(Uri url) async => true;

Future<bool> launchUrl(
  Uri url, {
  LaunchMode mode = LaunchMode.platformDefault,
}) async {
  final launched = await _channel.invokeMethod<bool>('launchUrl', url.toString());
  return launched ?? false;
}

