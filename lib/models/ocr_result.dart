import 'dart:ui';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class LensWord {
  final String text;
  final Rect boundingBox;
  bool isSelected;

  LensWord({
    required this.text,
    required this.boundingBox,
    this.isSelected = false,
  });
}

class LensLine {
  final String text;
  final Rect boundingBox;
  final List<LensWord> words;

  LensLine({
    required this.text,
    required this.boundingBox,
    required this.words,
  });
}

class LensBlock {
  final String text;
  final Rect boundingBox;
  final List<LensLine> lines;

  LensBlock({
    required this.text,
    required this.boundingBox,
    required this.lines,
  });
}

class LensOcrResult {
  final String fullText;
  final Size imageSize;
  final List<LensBlock> blocks;

  LensOcrResult({
    required this.fullText,
    required this.imageSize,
    required this.blocks,
  });

  factory LensOcrResult.fromRecognizedText(RecognizedText recognized, Size imageSize) {
    List<LensBlock> parsedBlocks = [];

    for (var b in recognized.blocks) {
      List<LensLine> parsedLines = [];
      for (var l in b.lines) {
        List<LensWord> parsedWords = [];
        for (var w in l.elements) {
          parsedWords.add(LensWord(
            text: w.text,
            boundingBox: w.boundingBox,
          ));
        }
        parsedLines.add(LensLine(
          text: l.text,
          boundingBox: l.boundingBox,
          words: parsedWords,
        ));
      }
      parsedBlocks.add(LensBlock(
        text: b.text,
        boundingBox: b.boundingBox,
        lines: parsedLines,
      ));
    }

    return LensOcrResult(
      fullText: recognized.text,
      imageSize: imageSize,
      blocks: parsedBlocks,
    );
  }

  /// Get all selected text in natural reading order
  String getSelectedText() {
    List<String> selectedWords = [];
    for (var b in blocks) {
      for (var l in b.lines) {
        for (var w in l.words) {
          if (w.isSelected) {
            selectedWords.add(w.text);
          }
        }
      }
    }
    return selectedWords.join(' ').trim();
  }

  /// Deselect all words
  void clearSelection() {
    for (var b in blocks) {
      for (var l in b.lines) {
        for (var w in l.words) {
          w.isSelected = false;
        }
      }
    }
  }

  /// Select all words
  void selectAll() {
    for (var b in blocks) {
      for (var l in b.lines) {
        for (var w in l.words) {
          w.isSelected = true;
        }
      }
    }
  }
}
