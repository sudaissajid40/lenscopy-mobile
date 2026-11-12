import 'package:flutter/material.dart';
import '../../models/ocr_result.dart';

class LensBoundingPainter extends CustomPainter {
  final LensOcrResult ocrResult;
  final Size renderSize;
  final Rect? selectionBox;

  LensBoundingPainter({
    required this.ocrResult,
    required this.renderSize,
    this.selectionBox,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (ocrResult.imageSize.width == 0 || ocrResult.imageSize.height == 0) return;

    final double scaleX = renderSize.width / ocrResult.imageSize.width;
    final double scaleY = renderSize.height / ocrResult.imageSize.height;

    // Paint for unselected words (soft outline guide)
    final unselectedPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Paint for selected words (Google Lens glowing highlight)
    final selectedFillPaint = Paint()
      ..color = const Color(0xFF6366F1).withOpacity(0.35)
      ..style = PaintingStyle.fill;

    final selectedBorderPaint = Paint()
      ..color = const Color(0xFF818CF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var block in ocrResult.blocks) {
      for (var line in block.lines) {
        for (var word in line.words) {
          final scaledRect = Rect.fromLTRB(
            word.boundingBox.left * scaleX,
            word.boundingBox.top * scaleY,
            word.boundingBox.right * scaleX,
            word.boundingBox.bottom * scaleY,
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

    // Paint drag-selection rectangle if currently dragging
    if (selectionBox != null) {
      final dragFill = Paint()
        ..color = const Color(0xFF38BDF8).withOpacity(0.2)
        ..style = PaintingStyle.fill;
      final dragBorder = Paint()
        ..color = const Color(0xFF38BDF8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      final rrect = RRect.fromRectAndRadius(selectionBox!, const Radius.circular(6));
      canvas.drawRRect(rrect, dragFill);
      canvas.drawRRect(rrect, dragBorder);
    }
  }

  @override
  bool shouldRepaint(covariant LensBoundingPainter oldDelegate) {
    return true;
  }
}
