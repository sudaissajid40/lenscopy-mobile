import 'dart:async';
import 'dart:io';
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

  /// Process image file locally with Google ML Kit
  Future<LensOcrResult> processImageFile(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);

    // Get actual image dimensions
    final bytes = await imageFile.readAsBytes();
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (ui.Image img) {
      completer.complete(img);
    });
    final decodedImage = await completer.future;
    final size = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());

    final recognizedText = await recognizer.processImage(inputImage);
    return LensOcrResult.fromRecognizedText(recognizedText, size);
  }

  /// Deep scan a specific cropped region of the image with contrast enhancement and upscaling
  Future<LensOcrResult> deepScanCrop(File imageFile, Rect cropRect) async {
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

    // Determine optimal scaling: for small crops, upscale 2x-3x so ML Kit has high pixel density
    double scale = 1.0;
    if (cropW < 600 || cropH < 300) {
      scale = 2.0;
    }
    if (cropW < 300 || cropH < 150) {
      scale = 3.0;
    }

    final targetW = (cropW * scale).round();
    final targetH = (cropH * scale).round();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Apply high quality filter and contrast boost
    // Matrix enhances contrast so faint text stands out sharply
    const contrast = 1.35;
    const brightness = -20.0;
    const contrastMatrix = <double>[
      contrast, 0, 0, 0, brightness,
      0, contrast, 0, 0, brightness,
      0, 0, contrast, 0, brightness,
      0, 0, 0, 1.0, 0,
    ];

    final paint = Paint()
      ..filterQuality = ui.FilterQuality.high
      ..isAntiAlias = true
      ..colorFilter = const ColorFilter.matrix(contrastMatrix);

    canvas.drawImageRect(
      fullImage,
      Rect.fromLTWH(left, top, cropW, cropH),
      Rect.fromLTWH(0, 0, targetW.toDouble(), targetH.toDouble()),
      paint,
    );

    final picture = recorder.endRecording();
    final croppedImage = await picture.toImage(targetW, targetH);
    final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      return LensOcrResult(fullText: '', imageSize: Size(cropW, cropH), blocks: []);
    }

    // Write temporary file for ML Kit
    final tempDir = Directory.systemTemp;
    final tempCropFile = File('${tempDir.path}/lens_snip_${DateTime.now().millisecondsSinceEpoch}.png');
    await tempCropFile.writeAsBytes(byteData.buffer.asUint8List());

    try {
      final inputImage = InputImage.fromFile(tempCropFile);
      final recognizedText = await recognizer.processImage(inputImage);

      // Map recognized coordinates back from (upscaled crop) to original image coordinate space
      return LensOcrResult.fromRecognizedTextWithOffset(
        recognizedText,
        cropSize: Size(cropW, cropH),
        cropOffset: Offset(left, top),
        scaleRatio: scale,
      );
    } finally {
      if (await tempCropFile.exists()) {
        await tempCropFile.delete();
      }
    }
  }

  /// Deep scan the full image with contrast enhancement
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
