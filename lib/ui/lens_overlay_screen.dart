import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/ocr_result.dart';
import '../../services/clipboard_service.dart';
import '../../services/ocr_service.dart';
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

class _LensOverlayScreenState extends State<LensOverlayScreen>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformController = TransformationController();
  late AnimationController _laserController;

  Rect? _dragSelectionBox;
  Rect? _activeSnipBox;
  Offset? _dragStart;
  String _selectedText = '';
  bool _isDeepScanning = false;
  bool _isPanZoomMode = false;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _laserController.addListener(() {
      setState(() {});
    });
    _updateSelectedText();
  }

  @override
  void dispose() {
    _laserController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _updateSelectedText() {
    setState(() {
      _selectedText = widget.ocrResult.getSelectedText();
    });
  }

  /// Calculates the exact rectangle occupied by the image inside the container
  /// under BoxFit.contain (accounting for letterbox/pillarbox bars).
  Rect _calculateFittedRect(Size containerSize, Size imageSize) {
    if (imageSize.width <= 0 ||
        imageSize.height <= 0 ||
        containerSize.width <= 0 ||
        containerSize.height <= 0) {
      return Rect.zero;
    }
    final double scale = math.min(
      containerSize.width / imageSize.width,
      containerSize.height / imageSize.height,
    );
    final double renderedWidth = imageSize.width * scale;
    final double renderedHeight = imageSize.height * scale;
    final double offsetX = (containerSize.width - renderedWidth) / 2.0;
    final double offsetY = (containerSize.height - renderedHeight) / 2.0;
    return Rect.fromLTWH(offsetX, offsetY, renderedWidth, renderedHeight);
  }

  /// Maps a bounding box from screen coordinates to raw image pixel coordinates.
  Rect _mapScreenBoxToImage(Rect screenBox, Rect fittedRect, Size imageSize) {
    if (fittedRect.width <= 0 || imageSize.width <= 0) return Rect.zero;
    final double scale = fittedRect.width / imageSize.width;

    final double imgLeft = ((screenBox.left - fittedRect.left) / scale).clamp(0.0, imageSize.width);
    final double imgTop = ((screenBox.top - fittedRect.top) / scale).clamp(0.0, imageSize.height);
    final double imgRight = ((screenBox.right - fittedRect.left) / scale).clamp(0.0, imageSize.width);
    final double imgBottom = ((screenBox.bottom - fittedRect.top) / scale).clamp(0.0, imageSize.height);

    return Rect.fromLTRB(
      math.min(imgLeft, imgRight),
      math.min(imgTop, imgBottom),
      math.max(imgLeft, imgRight),
      math.max(imgTop, imgBottom),
    );
  }

  /// Handles tapping on the image to select/toggle words
  void _handleTapUp(TapUpDetails details, Rect fittedRect) {
    if (_isPanZoomMode || widget.ocrResult.imageSize.width == 0 || fittedRect.isEmpty) return;

    final double scale = fittedRect.width / widget.ocrResult.imageSize.width;
    final tapPos = details.localPosition;

    bool hit = false;
    for (var block in widget.ocrResult.blocks) {
      for (var line in block.lines) {
        for (var word in line.words) {
          final scaledRect = Rect.fromLTRB(
            fittedRect.left + (word.boundingBox.left * scale),
            fittedRect.top + (word.boundingBox.top * scale),
            fittedRect.left + (word.boundingBox.right * scale),
            fittedRect.top + (word.boundingBox.bottom * scale),
          );

          if (scaledRect.inflate(6.0).contains(tapPos)) {
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
      // Tap outside clears selection and active snip box
      setState(() {
        _activeSnipBox = null;
        widget.ocrResult.clearSelection();
      });
    }
    _updateSelectedText();
  }

  void _handlePanStart(DragStartDetails details) {
    if (_isPanZoomMode) return;
    setState(() {
      _dragStart = details.localPosition;
      _dragSelectionBox = Rect.fromPoints(_dragStart!, _dragStart!);
      _activeSnipBox = null;
    });
  }

  void _handlePanUpdate(DragUpdateDetails details, Rect fittedRect) {
    if (_isPanZoomMode || _dragStart == null) return;
    setState(() {
      _dragSelectionBox = Rect.fromPoints(_dragStart!, details.localPosition);
      _selectWordsInBox(_dragSelectionBox!, fittedRect);
    });
  }

  void _handlePanEnd(DragEndDetails details, Rect fittedRect) {
    if (_isPanZoomMode || _dragSelectionBox == null) return;
    setState(() {
      if (_dragSelectionBox!.width > 20 && _dragSelectionBox!.height > 20) {
        _activeSnipBox = _dragSelectionBox;
      } else {
        _activeSnipBox = null;
      }
      _dragSelectionBox = null;
      _dragStart = null;
    });
    _updateSelectedText();
  }

  void _selectWordsInBox(Rect box, Rect fittedRect) {
    if (fittedRect.isEmpty || widget.ocrResult.imageSize.width == 0) return;
    final double scale = fittedRect.width / widget.ocrResult.imageSize.width;

    for (var block in widget.ocrResult.blocks) {
      for (var line in block.lines) {
        for (var word in line.words) {
          final scaledRect = Rect.fromLTRB(
            fittedRect.left + (word.boundingBox.left * scale),
            fittedRect.top + (word.boundingBox.top * scale),
            fittedRect.left + (word.boundingBox.right * scale),
            fittedRect.top + (word.boundingBox.bottom * scale),
          );

          if (box.overlaps(scaledRect)) {
            word.isSelected = true;
          }
        }
      }
    }
  }

  /// Triggers High-Precision Deep Scanning on the Snipped Region
  Future<void> _performDeepScanSnip(Rect fittedRect) async {
    if (_activeSnipBox == null || _isDeepScanning) return;

    final imageCropRect = _mapScreenBoxToImage(_activeSnipBox!, fittedRect, widget.ocrResult.imageSize);
    if (imageCropRect.width < 10 || imageCropRect.height < 10) return;

    setState(() {
      _isDeepScanning = true;
    });
    _laserController.repeat(reverse: true);

    try {
      final deepResult = await OcrService().deepScanCrop(widget.imageFile, imageCropRect);

      setState(() {
        widget.ocrResult.mergeDeepScan(deepResult, imageCropRect);
        _updateSelectedText();
      });

      if (mounted) {
        final count = deepResult.getSelectedText().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF60A5FA), size: 20),
                const SizedBox(width: 10),
                Text(
                  count == 0
                      ? 'Deep scan: No clear text found in snip area'
                      : 'Deep scan complete: $count words extracted!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deep scan error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeepScanning = false;
        });
        _laserController.stop();
        _laserController.reset();
      }
    }
  }

  /// Deep scan the whole image with adaptive contrast enhancement
  Future<void> _performDeepScanFull() async {
    if (_isDeepScanning) return;

    setState(() {
      _isDeepScanning = true;
      _activeSnipBox = null;
    });

    try {
      final deepResult = await OcrService().deepScanFull(widget.imageFile);

      setState(() {
        widget.ocrResult.blocks.clear();
        widget.ocrResult.blocks.addAll(deepResult.blocks);
        widget.ocrResult.fullText = deepResult.fullText;
        widget.ocrResult.selectAll();
        _updateSelectedText();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.auto_awesome, color: Color(0xFF34D399), size: 20),
                SizedBox(width: 10),
                Text('Full image deep scan completed! All text selected.', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Full scan error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeepScanning = false;
        });
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
      _activeSnipBox = null;
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
        title: const Text(
          'Google Lens Selection',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          // Mode Toggle: Snip Area vs Zoom/Pan
          IconButton(
            tooltip: _isPanZoomMode ? 'Switch to Snip & Select' : 'Switch to Zoom & Pan',
            icon: Icon(
              _isPanZoomMode ? Icons.crop_free_rounded : Icons.pinch_rounded,
              color: _isPanZoomMode ? const Color(0xFF60A5FA) : Colors.white70,
            ),
            onPressed: () {
              setState(() {
                _isPanZoomMode = !_isPanZoomMode;
                if (_isPanZoomMode) {
                  _activeSnipBox = null;
                  _dragSelectionBox = null;
                }
              });
            },
          ),
          // Deep Scan Full Image Action
          IconButton(
            tooltip: 'Deep Scan Entire Image',
            icon: const Icon(Icons.auto_awesome, color: Color(0xFF818CF8)),
            onPressed: _isDeepScanning ? null : _performDeepScanFull,
          ),
          TextButton(
            onPressed: _selectAll,
            child: const Text(
              'Select All',
              style: TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final containerSize = Size(constraints.maxWidth, constraints.maxHeight);
          final fittedRect = _calculateFittedRect(containerSize, widget.ocrResult.imageSize);

          final effectiveSnipBox = _dragSelectionBox ?? _activeSnipBox;

          return Stack(
            fit: StackFit.expand,
            children: [
              // Zoomable / Interactive Image Viewport
              InteractiveViewer(
                transformationController: _transformController,
                panEnabled: _isPanZoomMode,
                scaleEnabled: _isPanZoomMode,
                minScale: 0.8,
                maxScale: 4.0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) => _handleTapUp(details, fittedRect),
                  onPanStart: _handlePanStart,
                  onPanUpdate: (details) => _handlePanUpdate(details, fittedRect),
                  onPanEnd: (details) => _handlePanEnd(details, fittedRect),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // The Image rendered with contain
                      Image.file(
                        widget.imageFile,
                        fit: BoxFit.contain,
                      ),
                      // Pixel-perfect Bounding Box & Snip Painter
                      CustomPaint(
                        size: containerSize,
                        painter: LensBoundingPainter(
                          ocrResult: widget.ocrResult,
                          fittedImageRect: fittedRect,
                          selectionBox: effectiveSnipBox,
                          isScanning: _isDeepScanning,
                          scanProgress: _laserController.value,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Floating Snip Deep Scan Action Pill
              if (_activeSnipBox != null && !_isDeepScanning)
                Positioned(
                  left: (_activeSnipBox!.left + (_activeSnipBox!.width / 2) - 80)
                      .clamp(16.0, containerSize.width - 180.0),
                  top: (_activeSnipBox!.bottom + 12.0 < containerSize.height - 130)
                      ? _activeSnipBox!.bottom + 12.0
                      : (_activeSnipBox!.top - 46.0).clamp(16.0, containerSize.height - 130),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF312E81), Color(0xFF1E1B4B)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF818CF8), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.4),
                            blurRadius: 14,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => _performDeepScanSnip(fittedRect),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.auto_awesome, color: Color(0xFF60A5FA), size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Deep Scan Snip',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Top Scanning Indicator Bar if Deep Scan is processing
              if (_isDeepScanning)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: const Color(0xFF1E1B4B).withOpacity(0.9),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF60A5FA),
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Deep Scanning text at high resolution...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
