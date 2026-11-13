import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/ocr_result.dart';

class OcrService {
  static final OcrService _instance = OcrService._internal();
  factory OcrService() => _instance;
  OcrService._internal();

  TextRecognizer? _recognizer;

  TextRecognizer get recognizer {
    _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    return _recognizer!;
  }

  /// Process image file locally with Chrome-extension default preprocessing pipeline:
  /// Adaptive scaling (1.5x-2.0x) + contrast stretch + dual-polarity check
  Future<LensOcrResult> processImageFile(File imageFile) async {
    // Get actual image dimensions
    final bytes = await imageFile.readAsBytes();
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (ui.Image img) {
      completer.complete(img);
    });
    final decodedImage = await completer.future;
    final size = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());

    // Chrome Extension "auto" default pipeline:
    // Scale factor: <=1366px -> 2.0x, <=1920px -> 1.5x, else 1.0x
    double scale = 1.0;
    if (size.width <= 1366) {
      scale = 2.0;
    } else if (size.width <= 1920) {
      scale = 1.5;
    }

    // Cap maximum dimension to 4096 to prevent memory issues
    if (size.width * scale > 4096 || size.height * scale > 4096) {
      scale = math.min(4096 / size.width, 4096 / size.height);
    }

    final targetW = (size.width * scale).round();
    final targetH = (size.height * scale).round();

    // 1. Primary Pass: Auto-Enhanced Image (upscaled + contrast-boosted)
    LensOcrResult? result;
    final enhancedFile = await _renderProcessedCrop(
      decodedImage,
      Rect.fromLTWH(0, 0, size.width, size.height),
      targetW,
      targetH,
      invert: false,
      contrast: 1.35,
      brightness: -20.0,
    );

    if (enhancedFile != null) {
      try {
        final recognized = await recognizer.processImage(InputImage.fromFile(enhancedFile));
        result = LensOcrResult.fromRecognizedTextWithOffset(
          recognized,
          cropSize: size,
          cropOffset: Offset.zero,
          scaleRatio: scale,
          defaultSelected: false,
        );
      } finally {
        if (await enhancedFile.exists()) {
          await enhancedFile.delete();
        }
      }
    }

    // 2. Secondary Pass: If enhanced pass found sparse text (<15 chars), test raw image
    if (result == null || result.fullText.trim().length < 15) {
      final rawRecognized = await recognizer.processImage(InputImage.fromFile(imageFile));
      final rawResult = LensOcrResult.fromRecognizedText(rawRecognized, size);
      if (rawResult.fullText.trim().length > (result?.fullText.trim().length ?? 0)) {
        result = rawResult;
      }
    }

    // 3. Dual-Polarity Check: If text is still sparse (e.g. white text on dark background / dark mode screenshots),
    // perform inverted contrast pass
    if (result == null || result.fullText.trim().length < 15) {
      final invertedResult = await deepScanCrop(
        imageFile,
        Rect.fromLTWH(0, 0, size.width, size.height),
        forceInvert: true,
      );
      if (invertedResult.fullText.trim().length > (result?.fullText.trim().length ?? 0)) {
        result = invertedResult;
      }
    }

    return result ?? LensOcrResult(fullText: '', imageSize: size, blocks: []);
  }

  /// Deep scan a specific cropped region with adaptive upscaling, contrast boost, and dual-polarity check
  Future<LensOcrResult> deepScanCrop(
    File imageFile,
    Rect cropRect, {
    bool forceInvert = false,
  }) async {
    final bytes = await imageFile.readAsBytes();
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (ui.Image img) {
      completer.complete(img);
    });
    final fullImage = await completer.future;

    // Clamp crop rect to valid image bounds
    final double left = cropRect.left.clamp(0.0, fullImage.width.toDouble());
    final double top = cropRect.top.clamp(0.0, fullImage.height.toDouble());
    final double right = cropRect.right.clamp(left + 10.0, fullImage.width.toDouble());
    final double bottom = cropRect.bottom.clamp(top + 10.0, fullImage.height.toDouble());

    final double cropW = right - left;
    final double cropH = bottom - top;

    if (cropW <= 0 || cropH <= 0) {
      return LensOcrResult(fullText: '', imageSize: Size.zero, blocks: []);
    }

    // Adaptive Scaling (similar to Chrome extension ocr.js):
    // Small text snippet (<500px): 3x upscale
    // Medium snippet (<1000px): 2x upscale
    // High res snippet: 1.5x upscale
    double scale = 1.0;
    if (cropW < 500 || cropH < 250) {
      scale = 3.0;
    } else if (cropW < 1000 || cropH < 500) {
      scale = 2.0;
    } else {
      scale = 1.5;
    }

    // Cap maximum dimension to 4096 to prevent OOM
    if (cropW * scale > 4096 || cropH * scale > 4096) {
      scale = math.min(4096 / cropW, 4096 / cropH);
    }

    final targetW = (cropW * scale).round();
    final targetH = (cropH * scale).round();

    // 1. Render Normal Enhanced Pass
    final normalCropFile = await _renderProcessedCrop(
      fullImage,
      Rect.fromLTWH(left, top, cropW, cropH),
      targetW,
      targetH,
      invert: forceInvert,
      contrast: 1.4,
      brightness: -25.0,
    );

    LensOcrResult? bestResult;

    try {
      if (normalCropFile != null) {
        final recognizedNormal = await recognizer.processImage(InputImage.fromFile(normalCropFile));
        bestResult = LensOcrResult.fromRecognizedTextWithOffset(
          recognizedNormal,
          cropSize: Size(cropW, cropH),
          cropOffset: Offset(left, top),
          scaleRatio: scale,
        );
      }
    } finally {
      if (normalCropFile != null && await normalCropFile.exists()) {
        await normalCropFile.delete();
      }
    }

    // 2. Dual Polarity Check: If normal pass produced empty or sparse result and wasn't already inverted,
    // run inverted polarity pass (crucial for white text on dark background / dark mode screenshots)
    if (!forceInvert && (bestResult == null || bestResult.fullText.trim().length < 8)) {
      final invertedCropFile = await _renderProcessedCrop(
        fullImage,
        Rect.fromLTWH(left, top, cropW, cropH),
        targetW,
        targetH,
        invert: true,
        contrast: 1.5,
        brightness: -30.0,
      );

      try {
        if (invertedCropFile != null) {
          final recognizedInverted = await recognizer.processImage(InputImage.fromFile(invertedCropFile));
          final invertedResult = LensOcrResult.fromRecognizedTextWithOffset(
            recognizedInverted,
            cropSize: Size(cropW, cropH),
            cropOffset: Offset(left, top),
            scaleRatio: scale,
          );

          if (bestResult == null || invertedResult.fullText.trim().length > bestResult.fullText.trim().length) {
            bestResult = invertedResult;
          }
        }
      } finally {
        if (invertedCropFile != null && await invertedCropFile.exists()) {
          await invertedCropFile.delete();
        }
      }
    }

    return bestResult ?? LensOcrResult(fullText: '', imageSize: Size(cropW, cropH), blocks: []);
  }

  /// Helper to render filtered, contrast-stretched, and upscaled sub-image using hardware accelerated dart:ui
  Future<File?> _renderProcessedCrop(
    ui.Image source,
    Rect srcRect,
    int targetW,
    int targetH, {
    required bool invert,
    required double contrast,
    required double brightness,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // ColorFilter matrix:
    // If invert == true: -1.0 * contrast, with offset
    final double factor = invert ? -contrast : contrast;
    final double offset = invert ? 255.0 + brightness : brightness;

    final contrastMatrix = <double>[
      factor, 0, 0, 0, offset,
      0, factor, 0, 0, offset,
      0, 0, factor, 0, offset,
      0, 0, 0, 1.0, 0,
    ];

    final paint = Paint()
      ..filterQuality = ui.FilterQuality.high
      ..isAntiAlias = true
      ..colorFilter = ColorFilter.matrix(contrastMatrix);

    canvas.drawImageRect(
      source,
      srcRect,
      Rect.fromLTWH(0, 0, targetW.toDouble(), targetH.toDouble()),
      paint,
    );

    final picture = recorder.endRecording();
    final croppedImage = await picture.toImage(targetW, targetH);
    final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) return null;

    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/snip_${DateTime.now().microsecondsSinceEpoch}.png');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file;
  }

  /// Deep scan the full image
  Future<LensOcrResult> deepScanFull(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (ui.Image img) {
      completer.complete(img);
    });
    final fullImage = await completer.future;

    return deepScanCrop(
      imageFile,
      Rect.fromLTWH(0, 0, fullImage.width.toDouble(), fullImage.height.toDouble()),
    );
  }

  void dispose() {
    _recognizer?.close();
    _recognizer = null;
  }
}
