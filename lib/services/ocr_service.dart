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

  void dispose() {
    _recognizer?.close();
    _recognizer = null;
  }
}
