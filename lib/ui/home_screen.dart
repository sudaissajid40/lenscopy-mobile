import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ocr_service.dart';
import '../services/screen_capture_service.dart';
import '../services/supabase_service.dart';
import 'clipboard_hub_screen.dart';
import 'lens_overlay_screen.dart';
import 'settings_screen.dart';

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
    SupabaseService().autoSync();

    // Check if launched from Top Taskbar / Quick Settings Tile
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final initialFile = await ScreenCaptureService.getInitialScreenshot();
      if (initialFile != null && mounted) {
        _processImage(initialFile, 'Screen OCR (Top Tile)');
      }
    });
  }

  Future<void> _processImage(File imageFile, String source) async {
    // Check scan quota
    final allowed = await SupabaseService().recordScan();
    if (!allowed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scan limit reached. Please upgrade to Premium or invite friends!'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Running on-device OCR...';
    });

    try {
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
        );
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

  Future<void> _scanCurrentScreen() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Capturing on-screen content...';
    });

    final screenFile = await ScreenCaptureService.captureCurrentScreen();
    if (screenFile != null) {
      await _processImage(screenFile, 'Screen OCR');
    } else {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Screen capture permission was not granted or cancelled.'),
            backgroundColor: Color(0xFFF59E0B),
          ),
        );
      }
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
          // Remaining Quota Badge
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
            child: Text(
              account.isPremium ? '★ Premium' : '${account.remainingScans} scans left',
              style: TextStyle(
                color: account.isPremium ? const Color(0xFF34D399) : const Color(0xFFA5B4FC),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
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
                  // Top Quick Settings Tile Tip Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
                    ),
                    child: Row(
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
                                'Top Taskbar / Quick Tile',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Swipe down your phone taskbar anytime to scan text on your current screen without opening the app!',
                                style: TextStyle(color: Colors.white60, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Big Action Card: Live Camera Scan
                  InkWell(
                    onTap: _captureCamera,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      height: 160,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.camera_alt_rounded, size: 54, color: Colors.white),
                          SizedBox(height: 12),
                          Text(
                            'Scan with Camera',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Google Lens interactive selection on photo',
                            style: TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Split Cards: Scan Screen & Pick from Gallery
                  Row(
                    children: [
                      // Scan Current Screen Button
                      Expanded(
                        child: InkWell(
                          onTap: _scanCurrentScreen,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Column(
                              children: const [
                                Icon(Icons.screenshot_monitor_rounded, color: Color(0xFF38BDF8), size: 36),
                                SizedBox(height: 10),
                                Text(
                                  'Scan Screen',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'OCR anything on display',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 11, color: Colors.white54),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Import Photo from Gallery
                      Expanded(
                        child: InkWell(
                          onTap: _pickGallery,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Column(
                              children: const [
                                Icon(Icons.photo_library_rounded, color: Color(0xFFA855F7), size: 36),
                                SizedBox(height: 10),
                                Text(
                                  'Import Photo',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'From phone gallery',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 11, color: Colors.white54),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Permanent Clipboard Hub Access Card
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ClipboardHubScreen()),
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.content_paste_rounded, color: Color(0xFF34D399), size: 24),
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
                          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white38),
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
