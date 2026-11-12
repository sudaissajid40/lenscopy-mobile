import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/clip_item.dart';
import '../../services/clipboard_service.dart';

class ClipboardHubScreen extends StatefulWidget {
  const ClipboardHubScreen({super.key});

  @override
  State<ClipboardHubScreen> createState() => _ClipboardHubScreenState();
}

class _ClipboardHubScreenState extends State<ClipboardHubScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'all';
  bool _pinnedOnly = false;

  @override
  void initState() {
    super.initState();
    ClipboardService().init().then((_) => setState(() {}));
  }

  void _copyClip(ClipItem clip) async {
    await ClipboardService().copyAndSave(clip.text, source: clip.source);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 18),
              SizedBox(width: 8),
              Text('Copied to clipboard!', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final clips = ClipboardService().filter(
      query: _searchCtrl.text,
      category: _selectedCategory,
      pinnedOnly: _pinnedOnly,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Clipboard Hub', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: Icon(
              _pinnedOnly ? Icons.push_pin_rounded : Icons.push_pin_outlined,
              color: _pinnedOnly ? const Color(0xFFF59E0B) : Colors.white70,
            ),
            tooltip: 'Show Pinned Only',
            onPressed: () => setState(() => _pinnedOnly = !_pinnedOnly),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
            onSelected: (val) async {
              if (val == 'clear_unpinned') {
                await ClipboardService().clearAll(keepPinned: true);
                setState(() {});
              } else if (val == 'clear_all') {
                await ClipboardService().clearAll(keepPinned: false);
                setState(() {});
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'clear_unpinned', child: Text('Clear Unpinned Clips')),
              const PopupMenuItem(value: 'clear_all', child: Text('Clear All Clips', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search clipboard history...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                        onPressed: () => setState(() => _searchCtrl.clear()),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF1E293B),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildCategoryChip('all', 'All Clips'),
                _buildCategoryChip('links', '🔗 Links'),
                _buildCategoryChip('emails', '✉ Emails'),
                _buildCategoryChip('code', '💻 Code'),
                _buildCategoryChip('text', '📄 Plain Text'),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Clips List
          Expanded(
            child: clips.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.content_paste_off_rounded, size: 48, color: Colors.white24),
                        SizedBox(height: 12),
                        Text('No clips found', style: TextStyle(color: Colors.white54, fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: clips.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final clip = clips[idx];
                      return _buildClipCard(clip);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String cat, String label) {
    final isSelected = _selectedCategory == cat;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontSize: 12)),
        selected: isSelected,
        selectedColor: const Color(0xFF6366F1),
        backgroundColor: const Color(0xFF1E293B),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onSelected: (_) => setState(() => _selectedCategory = cat),
      ),
    );
  }

  Widget _buildClipCard(ClipItem clip) {
    final timeStr = DateFormat('MMM d, h:mm a').format(clip.createdAt);

    return InkWell(
      onTap: () => _copyClip(clip),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: clip.isPinned ? const Color(0xFFF59E0B).withOpacity(0.5) : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Source, Date, Pin & Delete
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    clip.source,
                    style: const TextStyle(color: Color(0xFF818CF8), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(timeStr, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    clip.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                    color: clip.isPinned ? const Color(0xFFF59E0B) : Colors.white38,
                    size: 18,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () async {
                    await ClipboardService().togglePin(clip.id);
                    setState(() {});
                  },
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.share_rounded, color: Colors.white38, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Share.share(clip.text),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.white38, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () async {
                    await ClipboardService().deleteClip(clip.id);
                    setState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Clip Text
            Text(
              clip.text,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
