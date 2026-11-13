import 'package:flutter/material.dart';
import '../../services/screen_capture_service.dart';

class TaskbarTutorialDialog extends StatefulWidget {
  const TaskbarTutorialDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TaskbarTutorialDialog(),
    );
  }

  @override
  State<TaskbarTutorialDialog> createState() => _TaskbarTutorialDialogState();
}

class _TaskbarTutorialDialogState extends State<TaskbarTutorialDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _swipeAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _swipeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeInOut),
      ),
    );

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.55, 0.95, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _attemptAutoAddTile() async {
    try {
      await ScreenCaptureService.requestAddTile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Swipe down notification bar and tap ✏️ to add "LensCopy Scan" tile.'),
            backgroundColor: Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Swipe down notification bar and tap pencil ✏️ to add tile manually.'),
            backgroundColor: Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0xFF334155), width: 1.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.touch_app_rounded, color: Color(0xFF818CF8), size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Top Taskbar Quick Tile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white60),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Animated Phone Graphic Demonstration
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              final swipeOffset = _swipeAnim.value * 40.0;
              final shadeHeight = 50.0 + (_swipeAnim.value * 55.0);

              return Container(
                height: 190,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0B0F19)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Mock Phone Notch & Speaker
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 50,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Mock Sliding Quick Settings Shade
                    Positioned(
                      top: 14,
                      left: 14,
                      right: 14,
                      child: Container(
                        height: shadeHeight,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B).withOpacity(0.95),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMockTile(Icons.wifi_rounded, 'Wi-Fi', false),
                            _buildMockTile(Icons.bluetooth_rounded, 'Bluetooth', false),
                            _buildMockTile(Icons.flashlight_on_rounded, 'Torch', false),
                            // LensCopy Glowing Tile
                            Transform.scale(
                              scale: _pulseAnim.value,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF6366F1).withOpacity(0.6),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.document_scanner_rounded, color: Colors.white, size: 18),
                                    SizedBox(height: 2),
                                    Text('LensCopy', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Mock Finger Swipe Graphic
                    Positioned(
                      top: 4 + swipeOffset,
                      right: 40,
                      child: Opacity(
                        opacity: (1.0 - (_swipeAnim.value * 0.4)).clamp(0.2, 1.0),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8).withOpacity(0.25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF38BDF8),
                            size: 28,
                          ),
                        ),
                      ),
                    ),

                    // Bottom caption in graphic
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.flash_on_rounded, color: Color(0xFF34D399), size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Scan screen from Instagram, WhatsApp, PDFs, or Games',
                              style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 18),

          // 3 Clear Simple Steps
          _buildStep(
            number: '1',
            title: 'Swipe Down',
            desc: 'Swipe down from the top edge of your phone to open Quick Settings.',
          ),
          const SizedBox(height: 10),
          _buildStep(
            number: '2',
            title: 'Tap Edit ✏️',
            desc: 'Tap the pencil or edit icon at the top/bottom of your quick settings.',
          ),
          const SizedBox(height: 10),
          _buildStep(
            number: '3',
            title: 'Add LensCopy Scan',
            desc: 'Find "LensCopy Scan" tile and drag it to your active top tiles.',
          ),
          const SizedBox(height: 22),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _attemptAutoAddTile,
                  icon: const Icon(Icons.add_to_home_screen_rounded, size: 18),
                  label: const Text('Add Tile Automatically', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMockTile(IconData icon, String label, bool active) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF6366F1) : const Color(0xFF334155),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 8)),
        ],
      ),
    );
  }

  Widget _buildStep({required String number, required String title, required String desc}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFF6366F1),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
