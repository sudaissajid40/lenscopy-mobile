import 'dart:io';
import 'package:flutter/services.dart';

class ScreenCaptureService {
  static const MethodChannel _channel = MethodChannel('com.lenscopy.app/screen_capture');

  /// Check if the app was launched by the Quick Settings Tile with an auto-captured screenshot
  static Future<File?> getInitialScreenshot() async {
    if (!Platform.isAndroid) return null;
    try {
      final String? path = await _channel.invokeMethod('getInitialScreenshot');
      if (path != null && path.isNotEmpty) {
        final file = File(path);
        if (await file.exists()) {
          return file;
        }
      }
    } catch (e) {
      // Ignore
    }
    return null;
  }

  /// Requests the Android system to take a screenshot of whatever is currently on screen
  /// using MediaProjection API and saves it to a temporary image file.
  static Future<File?> captureCurrentScreen() async {
    if (!Platform.isAndroid) return null;
    try {
      final String? path = await _channel.invokeMethod('captureScreen');
      if (path != null && path.isNotEmpty) {
        final file = File(path);
        if (await file.exists()) {
          return file;
        }
      }
    } catch (e) {
      // Platform exception or user cancelled MediaProjection permission
    }
    return null;
  }

  /// Check if Quick Settings Tile service is supported and active
  static Future<bool> isTileAvailable() async {
    if (!Platform.isAndroid) return false;
    try {
      final bool? available = await _channel.invokeMethod('isTileAvailable');
      return available ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Request the system to prompt adding the Quick Settings Tile to top notification shade
  static Future<void> requestAddTile() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('requestAddTile');
    } catch (e) {
      // Ignore
    }
  }
}
