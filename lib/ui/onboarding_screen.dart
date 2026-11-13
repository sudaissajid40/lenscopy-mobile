import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';
import 'home_screen.dart';
import 'widgets/taskbar_tutorial_dialog.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _nameController = TextEditingController(text: 'LensCopy User');
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  bool _showKeyField = false;
  bool _isSaving = false;

  Future<void> _completeOnboarding() async {
    setState(() => _isSaving = true);

    final name = _nameController.text.trim().isEmpty ? 'LensCopy User' : _nameController.text.trim();
    final email = _emailController.text.trim().isEmpty ? null : _emailController.text.trim();
    final keyOrCode = _keyController.text.trim().isEmpty ? null : _keyController.text.trim();

    try {
      await SupabaseService().autoRegisterFreeUser(
        displayName: name,
        email: email,
        licenseKey: keyOrCode,
      );
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_onboarding', true);

    if (mounted) {
      setState(() => _isSaving = false);

      // Navigate to Home Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );

      // Show the Taskbar Quick Tile graphic guide
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          TaskbarTutorialDialog.show(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              // Hero Branding
              Center(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.4),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.document_scanner_rounded,
                    size: 52,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Welcome to LensCopy',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Google Lens intelligence for your entire phone.\nExtract text from any app, photos, and camera with 100% on-device AI.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 26),

              // Feature Highlights
              _buildFeatureRow(
                icon: Icons.touch_app_rounded,
                color: const Color(0xFF38BDF8),
                title: 'Top Taskbar Quick Tile',
                desc: 'Swipe down anytime to capture & scan what\'s on screen without leaving your app.',
              ),
              const SizedBox(height: 14),
              _buildFeatureRow(
                icon: Icons.auto_awesome,
                color: const Color(0xFF818CF8),
                title: 'Snip Area Deep Scanning',
                desc: 'Drag a box over tiny or blurry text to run high-resolution neural enhancement.',
              ),
              const SizedBox(height: 14),
              _buildFeatureRow(
                icon: Icons.content_paste_rounded,
                color: const Color(0xFF34D399),
                title: 'Permanent Clipboard Hub',
                desc: 'Auto-saves everything you copy with smart sorting for emails, links, and code.',
              ),

              const SizedBox(height: 28),

              // Get Details Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personalize Your Profile',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Set up your device name for clipboard sync and license recovery.',
                      style: TextStyle(fontSize: 12, color: Colors.white60),
                    ),
                    const SizedBox(height: 14),

                    // Name Field
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Your Name',
                        labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
                        prefixIcon: const Icon(Icons.person_rounded, color: Color(0xFF818CF8), size: 20),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Email Field (Optional)
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Email Address (Optional)',
                        labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
                        prefixIcon: const Icon(Icons.email_rounded, color: Color(0xFF38BDF8), size: 20),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Collapsible License / Invite Code field
                    if (!_showKeyField)
                      TextButton.icon(
                        onPressed: () => setState(() => _showKeyField = true),
                        icon: const Icon(Icons.key_rounded, size: 16, color: Color(0xFFA5B4FC)),
                        label: const Text(
                          'Have a License Key or Invite Code?',
                          style: TextStyle(color: Color(0xFFA5B4FC), fontSize: 12),
                        ),
                      )
                    else ...[
                      const SizedBox(height: 6),
                      TextField(
                        controller: _keyController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'License Key or Invite Code',
                          labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
                          prefixIcon: const Icon(Icons.vpn_key_rounded, color: Color(0xFFA855F7), size: 20),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Get Started CTA Button
              ElevatedButton(
                onPressed: _isSaving ? null : _completeOnboarding,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 6,
                  shadowColor: const Color(0xFF6366F1).withOpacity(0.5),
                ),
                child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Get Started',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
