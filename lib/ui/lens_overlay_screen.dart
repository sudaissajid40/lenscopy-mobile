import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/ocr_result.dart';
import '../../services/clipboard_service.dart';
import 'widgets/action_pill.dart';
import 'widgets/lens_bounding_painter.dart';

class LensOverlayScreen extends StatefulWidget {
  final File imageFile;
  final LensOcrResult ocrResult;
  final String source;

  const LensOverlayScreen({
    super.key,
    required this.imageFile,
    required this.ocrResult,
    required this.source,
  });

  @override
  State<LensOverlayScreen> createState() => _LensOverlayScreenState();
}

class _LensOverlayScreenState extends State<LensOverlayScreen> {
  final TransformationController _transformController = TransformationController();
  Rect? _dragSelectionBox;
  Offset? _dragStart;
  String _selectedText = '';

  @override
  void initState() {
    super.initState();
    _updateSelectedText();
  }

  void _updateSelectedText() {
    setState(() {
      _selectedText = widget.ocrResult.getSelectedText();
    });
  }

  /// Handles tapping on the image to select words or lines
  void _handleTapUp(TapUpDetails details, Size displaySize) {
    if (widget.ocrResult.imageSize.width == 0 || widget.ocrResult.imageSize.height == 0) return;

    final double scaleX = displaySize.width / widget.ocrResult.imageSize.width;
    final double scaleY = displaySize.height / widget.ocrResult.imageSize.height;
    final tapPos = details.localPosition;

    bool hit = false;
    for (var block in widget.ocrResult.blocks) {
      for (var line in block.lines) {
        for (var word in line.words) {
          final scaledRect = Rect.fromLTRB(
            word.boundingBox.left * scaleX,
            word.boundingBox.top * scaleY,
            word.boundingBox.right * scaleX,
            word.boundingBox.bottom * scaleY,
          );

          if (scaledRect.contains(tapPos)) {
            word.isSelected = !word.isSelected;
            hit = true;
            break;
          }
        }
        if (hit) break;
      }
      if (hit) break;
    }

    if (!hit) {
      // Tap outside clears selection
      widget.ocrResult.clearSelection();
    }
    _updateSelectedText();
  }

  void _handlePanStart(DragStartDetails details) {
    setState(() {
      _dragStart = details.localPosition;
      _dragSelectionBox = Rect.fromPoints(_dragStart!, _dragStart!);
    });
  }

  void _handlePanUpdate(DragUpdateDetails details, Size displaySize) {
    if (_dragStart == null) return;
    setState(() {
      _dragSelectionBox = Rect.fromPoints(_dragStart!, details.localPosition);
      _selectWordsInBox(_dragSelectionBox!, displaySize);
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      _dragSelectionBox = null;
      _dragStart = null;
    });
    _updateSelectedText();
  }

  void _selectWordsInBox(Rect box, Size displaySize) {
    final double scaleX = displaySize.width / widget.ocrResult.imageSize.width;
    final double scaleY = displaySize.height / widget.ocrResult.imageSize.height;

    for (var block in widget.ocrResult.blocks) {
      for (var line in block.lines) {
        for (var word in line.words) {
          final scaledRect = Rect.fromLTRB(
            word.boundingBox.left * scaleX,
            word.boundingBox.top * scaleY,
            word.boundingBox.right * scaleX,
            word.boundingBox.bottom * scaleY,
          );

          if (box.overlaps(scaledRect)) {
            word.isSelected = true;
          }
        }
      }
    }
  }

  Future<void> _copySelectedText() async {
    final textToCopy = _selectedText.isNotEmpty ? _selectedText : widget.ocrResult.fullText;
    if (textToCopy.trim().isEmpty) return;

    await ClipboardService().copyAndSave(textToCopy, source: widget.source);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 20),
              SizedBox(width: 10),
              Text('Copied to clipboard & saved in Hub!', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _selectAll() {
    setState(() {
      widget.ocrResult.selectAll();
      _updateSelectedText();
    });
  }

  void _clearSelection() {
    setState(() {
      widget.ocrResult.clearSelection();
      _updateSelectedText();
    });
  }

  void _shareText() {
    if (_selectedText.trim().isNotEmpty) {
      Share.share(_selectedText);
    }
  }

  Future<void> _searchText() async {
    if (_selectedText.trim().isEmpty) return;
    final query = Uri.encodeComponent(_selectedText.trim());
    final url = Uri.parse('https://www.google.com/search?q=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Google Lens Selection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _selectAll,
            child: const Text('Select All', style: TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final displaySize = Size(constraints.maxWidth, constraints.maxHeight);

          return Stack(
            fit: StackFit.expand,
            children: [
              // Zoomable and Interactive Image Viewport
              InteractiveViewer(
                transformationController: _transformController,
                minScale: 0.8,
                maxScale: 4.0,
                child: GestureDetector(
                  onTapUp: (details) => _handleTapUp(details, displaySize),
                  onPanStart: _handlePanStart,
                  onPanUpdate: (details) => _handlePanUpdate(details, displaySize),
                  onPanEnd: _handlePanEnd,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        widget.imageFile,
                        fit: BoxFit.contain,
                      ),
                      CustomPaint(
                        size: displaySize,
                        painter: LensBoundingPainter(
                          ocrResult: widget.ocrResult,
                          renderSize: displaySize,
                          selectionBox: _dragSelectionBox,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Action Pill
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Center(
                    child: LensActionPill(
                      selectedText: _selectedText,
                      onCopy: _copySelectedText,
                      onSelectAll: _selectAll,
                      onShare: _shareText,
                      onSearch: _searchText,
                      onClear: _clearSelection,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
