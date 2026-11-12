import 'package:flutter/material.dart';
import '../../models/ocr_result.dart';

class LensBoundingPainter extends CustomPainter {
  final LensOcrResult ocrResult;
  final Rect fittedImageRect;
  final Rect? selectionBox;
  final bool isScanning;
  final double scanProgress;

  LensBoundingPainter({
    required this.ocrResult,
    required this.fittedImageRect,
    this.selectionBox,
    this.isScanning = false,
    this.scanProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (ocrResult.imageSize.width == 0 ||
        ocrResult.imageSize.height == 0 ||
        fittedImageRect.isEmpty) {
      return;
    }

    final double scale = fittedImageRect.width / ocrResult.imageSize.width;

    // Paint for unselected words (soft subtle guide)
    final unselectedPaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Paint for selected words (Google Lens glowing highlight)
    final selectedFillPaint = Paint()
      ..color = const Color(0xFF6366F1).withOpacity(0.35)
      ..style = PaintingStyle.fill;

    final selectedBorderPaint = Paint()
      ..color = const Color(0xFF818CF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    for (var block in ocrResult.blocks) {
      for (var line in block.lines) {
        for (var word in line.words) {
          final scaledRect = Rect.fromLTRB(
            fittedImageRect.left + (word.boundingBox.left * scale),
            fittedImageRect.top + (word.boundingBox.top * scale),
            fittedImageRect.left + (word.boundingBox.right * scale),
            fittedImageRect.top + (word.boundingBox.bottom * scale),
          );

          final rrect = RRect.fromRectAndRadius(scaledRect, const Radius.circular(4));

          if (word.isSelected) {
            canvas.drawRRect(rrect, selectedFillPaint);
            canvas.drawRRect(rrect, selectedBorderPaint);
          } else {
            canvas.drawRRect(rrect, unselectedPaint);
          }
        }
      }
    }

    // Paint drag-selection rectangle if currently dragging or active snip box
    if (selectionBox != null) {
      final b = selectionBox!;

      final dragFill = Paint()
        ..color = const Color(0xFF38BDF8).withOpacity(0.15)
        ..style = PaintingStyle.fill;

      final dragBorder = Paint()
        ..color = const Color(0xFF38BDF8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final rrect = RRect.fromRectAndRadius(b, const Radius.circular(8));
      canvas.drawRRect(rrect, dragFill);
      canvas.drawRRect(rrect, dragBorder);

      // Draw corner brackets for Google Lens style snip box
      final cornerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;

      const cornerLen = 14.0;

      // Top-Left
      canvas.drawLine(Offset(b.left, b.top + cornerLen), Offset(b.left, b.top), cornerPaint);
      canvas.drawLine(Offset(b.left, b.top), Offset(b.left + cornerLen, b.top), cornerPaint);

      // Top-Right
      canvas.drawLine(Offset(b.right - cornerLen, b.top), Offset(b.right, b.top), cornerPaint);
      canvas.drawLine(Offset(b.right, b.top), Offset(b.right, b.top + cornerLen), cornerPaint);

      // Bottom-Left
      canvas.drawLine(Offset(b.left, b.bottom - cornerLen), Offset(b.left, b.bottom), cornerPaint);
      canvas.drawLine(Offset(b.left, b.bottom), Offset(b.left + cornerLen, b.bottom), cornerPaint);

      // Bottom-Right
      canvas.drawLine(Offset(b.right - cornerLen, b.bottom), Offset(b.right, b.bottom), cornerPaint);
      canvas.drawLine(Offset(b.right, b.bottom), Offset(b.right, b.bottom - cornerLen), cornerPaint);

      // If deep scanning is in progress, draw a futuristic glowing scanning laser line
      if (isScanning) {
        final laserY = b.top + (b.height * scanProgress);
        final laserPaint = Paint()
          ..shader = const LinearGradient(
            colors: [
              Colors.transparent,
              Color(0xFF60A5FA),
              Colors.white,
              Color(0xFF60A5FA),
              Colors.transparent,
            ],
            stops: [0.0, 0.2, 0.5, 0.8, 1.0],
          ).createShader(Rect.fromLTWH(b.left, laserY - 2, b.width, 4))
          ..strokeWidth = 3.0;

        canvas.drawLine(Offset(b.left, laserY), Offset(b.right, laserY), laserPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant LensBoundingPainter oldDelegate) {
    return true;
  }
}
