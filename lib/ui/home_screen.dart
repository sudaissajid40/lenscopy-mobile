import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ocr_service.dart';
import '../services/screen_capture_service.dart';
import '../services/supabase_service.dart';
import 'clipboard_hub_screen.dart';
import 'lens_overlay_screen.dart';
import 'settings_screen.dart';
import 'widgets/taskbar_tutorial_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    // Auto-sync account state with server
    SupabaseService().autoSync().then((_) {
      if (mounted) setState(() {});
    });

    // Check if launched from Top Taskbar / Quick Settings Tile
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final initialFile = await ScreenCaptureService.getInitialScreenshot();
      if (initialFile != null && mounted) {
        _processImage(initialFile, 'Screen OCR (Top Tile)');
      }
    });
  }

  Future<void> _processImage(File imageFile, String source) async {
    final account = SupabaseService().account;
    if (!account.canScan) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Free limit reached (${account.dailyAllowance} scans/day). Upgrade to Premium or invite friends!',
            ),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Running neural OCR...';
    });

    try {
      await SupabaseService().recordScan();
      final ocrResult = await OcrService().processImageFile(imageFile);

      if (mounted) {
        setState(() => _isProcessing = false);

        if (ocrResult.fullText.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No text detected in this image.')),
          );
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LensOverlayScreen(
              imageFile: imageFile,
              ocrResult: ocrResult,
              source: source,
            ),
          ),
        ).then((_) {
          if (mounted) setState(() {});
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OCR Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _captureCamera() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 100);
    if (photo != null) {
      await _processImage(File(photo.path), 'Camera Scan');
    }
  }

  Future<void> _pickGallery() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
    if (photo != null) {
      await _processImage(File(photo.path), 'Gallery Import');
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = SupabaseService().account;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.document_scanner_rounded, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text(
              'LensCopy',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          // Remaining Quota / Premium Days Badge
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: account.isPremium
                  ? const Color(0xFF10B981).withOpacity(0.2)
                  : const Color(0xFF6366F1).withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: account.isPremium ? const Color(0xFF10B981) : const Color(0xFF818CF8),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  account.isPremium ? Icons.star_rounded : Icons.flash_on_rounded,
                  size: 14,
                  color: account.isPremium ? const Color(0xFF34D399) : const Color(0xFFA5B4FC),
                ),
                const SizedBox(width: 4),
                Text(
                  account.isPremium
                      ? '★ ${account.daysRemaining} days left'
                      : '${account.remainingScans}/${account.dailyAllowance} scans',
                  style: TextStyle(
                    color: account.isPremium ? const Color(0xFF34D399) : const Color(0xFFA5B4FC),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Colors.white70),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ).then((_) => setState(() {})),
          ),
        ],
      ),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF6366F1)),
                  const SizedBox(height: 20),
                  Text(_statusMessage, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Quick Settings Tile Banner with Animated Video/Graphic button
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.35)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF38BDF8).withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.touch_app_rounded, color: Color(0xFF38BDF8), size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Top Taskbar Quick Tile',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Scan your screen instantly from any app by swiping down your phone shade!',
                                    style: TextStyle(color: Colors.white60, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => TaskbarTutorialDialog.show(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF38BDF8).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.play_circle_fill_rounded, color: Color(0xFF38BDF8), size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Watch How to Add to Taskbar',
                                  style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Big Action Card: Live Camera Scan
                  InkWell(
                    onTap: _captureCamera,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.camera_alt_rounded, size: 50, color: Colors.white),
                          SizedBox(height: 10),
                          Text(
                            'Scan with Camera',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Interactive Google Lens selection on photo',
                            style: TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Import Photo from Gallery (Expanded clean full-width card)
                  InkWell(
                    onTap: _pickGallery,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFA855F7).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.photo_library_rounded, color: Color(0xFFA855F7), size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Import Photo / Screenshot',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Select an existing image from phone gallery to OCR',
                                  style: TextStyle(fontSize: 12, color: Colors.white54),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Permanent Clipboard Hub Access Card
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ClipboardHubScreen()),
                    ),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.content_paste_rounded, color: Color(0xFF34D399), size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Clipboard Hub & History',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Browse all past copied clips, pin favorites, and export',
                                  style: TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
