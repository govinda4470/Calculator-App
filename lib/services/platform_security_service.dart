import 'package:flutter/services.dart';

/// Thin wrapper around native controls for screens containing private data.
abstract final class PlatformSecurityService {
  static const _channel = MethodChannel('com.precision.calc/security');

  static Future<void> setSecureScreen(bool enabled) async {
    try {
      await _channel.invokeMethod<void>('setSecureScreen', {'enabled': enabled});
    } on MissingPluginException {
      // Tests and non-Android platforms do not install the Android channel.
    } on PlatformException {
      // Security UX must not crash the app if an OEM rejects a window flag.
    }
  }
}
