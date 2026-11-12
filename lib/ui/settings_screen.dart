import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/screen_capture_service.dart';
import '../../services/supabase_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isSyncing = false;
  final TextEditingController _nameCtrl = TextEditingController(text: 'LensCopy Mobile User');
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _licenseKeyCtrl = TextEditingController();
  final TextEditingController _inviteCodeCtrl = TextEditingController();

  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);
    await SupabaseService().autoSync();
    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account & License synced successfully!')),
      );
    }
  }

  void _showActivateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Activate License', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Colors.white70)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Email', labelStyle: TextStyle(color: Colors.white70)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _licenseKeyCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'License Key (Optional)',
                  hintText: 'LC-XXXX-XXXX-XXXX-XXXX',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _inviteCodeCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Invite Code (Optional)',
                  hintText: 'e.g. LC8F2A',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            onPressed: () async {
              try {
                await SupabaseService().activateLicense(
                  displayName: _nameCtrl.text,
                  email: _emailCtrl.text,
                  licenseKey: _licenseKeyCtrl.text,
                  inviteCode: _inviteCodeCtrl.text,
                );
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('License activated successfully!'), backgroundColor: Color(0xFF10B981)),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final account = SupabaseService().account;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Settings & License', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Account Status Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      account.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: account.isPremium
                            ? const Color(0xFF10B981).withOpacity(0.2)
                            : const Color(0xFF6366F1).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: account.isPremium ? const Color(0xFF10B981) : const Color(0xFF818CF8),
                        ),
                      ),
                      child: Text(
                        account.isPremium ? 'PREMIUM' : 'FREE TIER',
                        style: TextStyle(
                          color: account.isPremium ? const Color(0xFF34D399) : const Color(0xFFA5B4FC),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Account ID: ${account.accountId}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  account.isPremium
                      ? 'Status: ${account.daysRemaining} days remaining (Unlimited Scans)'
                      : 'Daily Allowance: ${account.todayScans} / ${account.dailyAllowance} scans used',
                  style: TextStyle(
                    color: account.isPremium ? const Color(0xFF34D399) : Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _showActivateDialog,
                      icon: const Icon(Icons.key_rounded, size: 16, color: Colors.white),
                      label: const Text('Enter License Key', style: TextStyle(color: Colors.white, fontSize: 13)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: _isSyncing ? null : _syncNow,
                      icon: _isSyncing
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.sync_rounded, size: 16, color: Colors.white70),
                      label: const Text('Sync', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white.withOpacity(0.2))),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Referral Reward Card
          if (account.inviteCode != null) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF2E1065)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFA855F7).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.card_giftcard_rounded, color: Color(0xFFA855F7), size: 22),
                      SizedBox(width: 10),
                      Text('Invite Friends & Earn Premium', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Share your invite link with colleagues. Each friend who installs instantly earns bonus Premier days for both of you!',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Code: ${account.inviteCode}',
                          style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: account.inviteLink ?? account.inviteCode!));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invite link copied!')));
                          },
                          icon: const Icon(Icons.copy_rounded, size: 14, color: Colors.white),
                          label: const Text('Copy', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share_rounded, size: 18, color: Colors.white70),
                          onPressed: () => Share.share(
                            'Try LensCopy - The fastest offline OCR & text copier for your phone: ${account.inviteLink ?? "https://lenscopy.app/invite/${account.inviteCode}"}',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Android Quick Settings Tile Setup Guide
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.tune_rounded, color: Color(0xFF38BDF8), size: 22),
                    SizedBox(width: 10),
                    Text('Top Notification Shade Shortcut', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'To scan text off any screen without switching apps:\n'
                  '1. Swipe down twice from the top of your phone.\n'
                  '2. Tap the Pencil / Edit icon to customize your Quick Settings tiles.\n'
                  '3. Drag "LensCopy Scan" into your active top tiles.\n'
                  '4. Now tap it anytime over Instagram, PDFs, or games to extract text!',
                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () => ScreenCaptureService.requestAddTile(),
                  icon: const Icon(Icons.add_to_home_screen_rounded, size: 16, color: Colors.white),
                  label: const Text('Prompt Add Tile to Top Bar', style: TextStyle(color: Colors.white, fontSize: 12)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
