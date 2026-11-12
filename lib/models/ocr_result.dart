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
  String fullText;
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

  /// Factory for results from an upscaled or cropped region mapped back to original image space
  factory LensOcrResult.fromRecognizedTextWithOffset(
    RecognizedText recognized, {
    required Size cropSize,
    required Offset cropOffset,
    required double scaleRatio,
  }) {
    List<LensBlock> parsedBlocks = [];

    for (var b in recognized.blocks) {
      List<LensLine> parsedLines = [];
      for (var l in b.lines) {
        List<LensWord> parsedWords = [];
        for (var w in l.elements) {
          final mappedBox = Rect.fromLTRB(
            cropOffset.dx + (w.boundingBox.left / scaleRatio),
            cropOffset.dy + (w.boundingBox.top / scaleRatio),
            cropOffset.dx + (w.boundingBox.right / scaleRatio),
            cropOffset.dy + (w.boundingBox.bottom / scaleRatio),
          );
          parsedWords.add(LensWord(
            text: w.text,
            boundingBox: mappedBox,
            isSelected: true,
          ));
        }
        final mappedLineBox = Rect.fromLTRB(
          cropOffset.dx + (l.boundingBox.left / scaleRatio),
          cropOffset.dy + (l.boundingBox.top / scaleRatio),
          cropOffset.dx + (l.boundingBox.right / scaleRatio),
          cropOffset.dy + (l.boundingBox.bottom / scaleRatio),
        );
        parsedLines.add(LensLine(
          text: l.text,
          boundingBox: mappedLineBox,
          words: parsedWords,
        ));
      }
      final mappedBlockBox = Rect.fromLTRB(
        cropOffset.dx + (b.boundingBox.left / scaleRatio),
        cropOffset.dy + (b.boundingBox.top / scaleRatio),
        cropOffset.dx + (b.boundingBox.right / scaleRatio),
        cropOffset.dy + (b.boundingBox.bottom / scaleRatio),
      );
      parsedBlocks.add(LensBlock(
        text: b.text,
        boundingBox: mappedBlockBox,
        lines: parsedLines,
      ));
    }

    return LensOcrResult(
      fullText: recognized.text,
      imageSize: cropSize,
      blocks: parsedBlocks,
    );
  }

  /// Merges deep scanned words/blocks from a snip into the current result.
  /// Removes any older overlapping words in the snip region and replaces them
  /// with the higher-accuracy deep scanned words.
  void mergeDeepScan(LensOcrResult deepResult, Rect snipImageRect) {
    clearSelection();

    // Remove existing words inside the snip region to avoid duplicate bounding boxes
    for (var block in blocks) {
      for (var line in block.lines) {
        line.words.removeWhere((w) => snipImageRect.contains(w.boundingBox.center));
      }
      block.lines.removeWhere((l) => l.words.isEmpty);
    }
    blocks.removeWhere((b) => b.lines.isEmpty);

    // Add the new deep scanned blocks
    blocks.addAll(deepResult.blocks);

    // Update fullText
    fullText = blocks.map((b) => b.text).join('\n');
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
