import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/clip_item.dart';
import '../services/clipboard_service.dart';
import 'widgets/taskbar_tutorial_dialog.dart';

class ClipboardHubScreen extends StatefulWidget {
  const ClipboardHubScreen({super.key});

  @override
  State<ClipboardHubScreen> createState() => _ClipboardHubScreenState();
}

class _ClipboardHubScreenState extends State<ClipboardHubScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'all';
  bool _starredOnly = false;
  bool _hasNotesOnly = false;
  String? _recentlyCopiedId;

  @override
  void initState() {
    super.initState();
    ClipboardService().init().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _copyClip(ClipItem clip) async {
    await Clipboard.setData(ClipboardData(text: clip.text));
    HapticFeedback.lightImpact();

    setState(() {
      _recentlyCopiedId = clip.id;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 18),
              SizedBox(width: 8),
              Text(
                'Copied to clipboard!',
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1400),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _recentlyCopiedId == clip.id) {
        setState(() {
          _recentlyCopiedId = null;
        });
      }
    });
  }

  Future<void> _toggleStar(ClipItem clip) async {
    HapticFeedback.mediumImpact();
    await ClipboardService().toggleStar(clip.id);
    setState(() {});
  }

  Future<void> _confirmDelete(ClipItem clip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 24),
            SizedBox(width: 10),
            Text('Delete Scan?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to remove this scan from your history? This action cannot be undone.',
          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ClipboardService().deleteClip(clip.id);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scan removed from history'),
            backgroundColor: Color(0xFF334155),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<void> _openNoteEditor(ClipItem clip) async {
    final noteCtrl = TextEditingController(text: clip.notes ?? '');

    final savedNote = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_note_rounded, color: Color(0xFF34D399), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clip.notes == null ? 'Add Note to Scan' : 'Edit Note',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('MMM d, yyyy • h:mm a').format(clip.createdAt),
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white60),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Snippet Preview of the scanned text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Text(
                  clip.text.length > 120 ? '${clip.text.substring(0, 120)}...' : clip.text,
                  style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 14),

              // Note Input
              TextField(
                controller: noteCtrl,
                autofocus: true,
                maxLines: 4,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Write your notes, tags, or reminders here...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF34D399), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Quick Tag Suggestions
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['#important', '#work', '#receipt', '#todo', '#code', '#reference'].map((tag) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(tag, style: const TextStyle(color: Color(0xFFA7F3D0), fontSize: 11)),
                        backgroundColor: const Color(0xFF10B981).withOpacity(0.12),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        onPressed: () {
                          if (!noteCtrl.text.contains(tag)) {
                            noteCtrl.text = (noteCtrl.text.trim() + ' ' + tag).trim();
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 18),

              // Buttons
              Row(
                children: [
                  if (clip.notes != null)
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(ctx, ''),
                        child: const Text('Delete Note', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  if (clip.notes != null) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(ctx, noteCtrl.text),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Save Note', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (savedNote != null) {
      await ClipboardService().updateNotes(clip.id, savedNote);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(savedNote.isEmpty ? 'Note removed' : 'Note saved successfully!'),
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  void _shareClip(ClipItem clip) {
    final buffer = StringBuffer();
    buffer.writeln(clip.text);
    if (clip.notes != null && clip.notes!.isNotEmpty) {
      buffer.writeln('\n--- Note ---');
      buffer.writeln(clip.notes);
    }
    Share.share(buffer.toString(), subject: 'LensCopy Scan');
  }

  @override
  Widget build(BuildContext context) {
    final allClips = ClipboardService().clips;
    final starredCount = allClips.where((c) => c.isStarred).length;
    final notesCount = allClips.where((c) => c.notes != null && c.notes!.trim().isNotEmpty).length;

    final filteredClips = ClipboardService().filter(
      query: _searchCtrl.text,
      category: _selectedCategory,
      starredOnly: _starredOnly,
      hasNotesOnly: _hasNotesOnly,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 1,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'History & Scans',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
            ),
            Text(
              '${allClips.length} Total • $starredCount Starred',
              style: const TextStyle(fontSize: 11, color: Colors.white54),
            ),
          ],
        ),
        actions: [
          // Star Filter Quick Toggle
          IconButton(
            tooltip: _starredOnly ? 'Show All Scans' : 'Filter Starred Scans',
            icon: Icon(
              _starredOnly ? Icons.star_rounded : Icons.star_outline_rounded,
              color: _starredOnly ? const Color(0xFFFBBF24) : Colors.white70,
              size: 24,
            ),
            onPressed: () {
              setState(() {
                _starredOnly = !_starredOnly;
                if (_starredOnly) _hasNotesOnly = false;
              });
            },
          ),

          // Top Taskbar Quick Tile Tutorial Button
          IconButton(
            tooltip: 'Add to Phone Top Taskbar',
            icon: const Icon(Icons.install_mobile_rounded, color: Color(0xFF60A5FA), size: 22),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const TaskbarTutorialDialog(),
              );
            },
          ),

          // Overflow Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (val) async {
              if (val == 'clear_unstarred') {
                await ClipboardService().clearAll(keepPinned: true);
                setState(() {});
              } else if (val == 'clear_all') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    title: const Text('Clear All History?', style: TextStyle(color: Colors.white)),
                    content: const Text(
                      'This will delete all scans, notes, and clips permanently.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ClipboardService().clearAll(keepPinned: false);
                  setState(() {});
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_unstarred',
                child: Row(
                  children: [
                    Icon(Icons.cleaning_services_rounded, color: Colors.white70, size: 18),
                    SizedBox(width: 10),
                    Text('Clear Unstarred', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 18),
                    SizedBox(width: 10),
                    Text('Clear All History', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Taskbar Quick Notification Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1B4B).withOpacity(0.6),
              border: Border(bottom: BorderSide(color: const Color(0xFF6366F1).withOpacity(0.2))),
            ),
            child: Row(
              children: [
                const Icon(Icons.swipe_down_rounded, color: Color(0xFF818CF8), size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Tip: Scan from any app via Phone Taskbar Tile',
                    style: TextStyle(color: Color(0xFFC7D2FE), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const TaskbarTutorialDialog(),
                    );
                  },
                  child: const Text(
                    'Setup Guide',
                    style: TextStyle(color: Color(0xFF60A5FA), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search scanned text & notes...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Colors.white38, size: 18),
                        onPressed: () => setState(() => _searchCtrl.clear()),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF1E293B),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                ),
              ),
            ),
          ),

          // Filter Chips (Categories + Starred + Notes)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'All (${allClips.length})',
                  isSelected: !_starredOnly && !_hasNotesOnly && _selectedCategory == 'all',
                  onSelected: () => setState(() {
                    _starredOnly = false;
                    _hasNotesOnly = false;
                    _selectedCategory = 'all';
                  }),
                ),
                _buildFilterChip(
                  label: '⭐ Starred ($starredCount)',
                  isSelected: _starredOnly,
                  activeColor: const Color(0xFFF59E0B),
                  onSelected: () => setState(() {
                    _starredOnly = !_starredOnly;
                    if (_starredOnly) _hasNotesOnly = false;
                  }),
                ),
                _buildFilterChip(
                  label: '📝 Notes ($notesCount)',
                  isSelected: _hasNotesOnly,
                  activeColor: const Color(0xFF10B981),
                  onSelected: () => setState(() {
                    _hasNotesOnly = !_hasNotesOnly;
                    if (_hasNotesOnly) _starredOnly = false;
                  }),
                ),
                _buildFilterChip(
                  label: '🔗 Links',
                  isSelected: _selectedCategory == 'links',
                  onSelected: () => setState(() {
                    _selectedCategory = _selectedCategory == 'links' ? 'all' : 'links';
                  }),
                ),
                _buildFilterChip(
                  label: '✉ Emails',
                  isSelected: _selectedCategory == 'emails',
                  onSelected: () => setState(() {
                    _selectedCategory = _selectedCategory == 'emails' ? 'all' : 'emails';
                  }),
                ),
                _buildFilterChip(
                  label: '💻 Code',
                  isSelected: _selectedCategory == 'code',
                  onSelected: () => setState(() {
                    _selectedCategory = _selectedCategory == 'code' ? 'all' : 'code';
                  }),
                ),
                _buildFilterChip(
                  label: '📄 Text',
                  isSelected: _selectedCategory == 'text',
                  onSelected: () => setState(() {
                    _selectedCategory = _selectedCategory == 'text' ? 'all' : 'text';
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // History List
          Expanded(
            child: filteredClips.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _starredOnly
                              ? Icons.star_border_rounded
                              : (_hasNotesOnly ? Icons.note_alt_outlined : Icons.content_paste_off_rounded),
                          size: 56,
                          color: Colors.white24,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _starredOnly
                              ? 'No starred scans yet'
                              : (_hasNotesOnly ? 'No scans with notes yet' : 'No history found'),
                          style: const TextStyle(color: Colors.white60, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _starredOnly
                              ? 'Tap "Add to Star" on any scan to save it here'
                              : 'Scanned text will automatically appear in your history',
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                    itemCount: filteredClips.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, idx) {
                      final clip = filteredClips[idx];
                      return _buildHistoryCard(clip);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    Color activeColor = const Color(0xFF6366F1),
    required VoidCallback onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withOpacity(0.25) : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? activeColor : Colors.white.withOpacity(0.08),
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(ClipItem clip) {
    final timeStr = DateFormat('MMM d, h:mm a').format(clip.createdAt);
    final hasNotes = clip.notes != null && clip.notes!.trim().isNotEmpty;
    final isRecentlyCopied = _recentlyCopiedId == clip.id;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: clip.isStarred
              ? const Color(0xFFF59E0B).withOpacity(0.6)
              : Colors.white.withOpacity(0.08),
          width: clip.isStarred ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Source Badge, Date, and Star status
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.document_scanner_rounded, color: Color(0xFFA5B4FC), size: 12),
                      const SizedBox(width: 4),
                      Text(
                        clip.source,
                        style: const TextStyle(
                          color: Color(0xFFA5B4FC),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(timeStr, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                const Spacer(),
                if (clip.isStarred)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 13),
                        SizedBox(width: 3),
                        Text(
                          'Starred',
                          style: TextStyle(color: Color(0xFFFBBF24), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Scanned Text Area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SelectableText(
              clip.text,
              maxLines: 6,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                height: 1.45,
                letterSpacing: 0.1,
              ),
            ),
          ),

          // User Notes Box (if notes exist)
          if (hasNotes)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 2),
              child: InkWell(
                onTap: () => _openNoteEditor(clip),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF064E3B).withOpacity(0.35),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.sticky_note_2_rounded, color: Color(0xFF34D399), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Personal Note:',
                              style: TextStyle(
                                color: Color(0xFF6EE7B7),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              clip.notes!,
                              style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.edit_rounded, color: Color(0xFF34D399), size: 14),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 8),
          const Divider(color: Colors.white12, height: 1),

          // Action Keys Bar: Delete, Copy, Add to Star, Note, Share
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Star / Add to Star Button
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: clip.isStarred ? const Color(0xFFFBBF24) : Colors.white70,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: clip.isStarred ? const Color(0xFFF59E0B).withOpacity(0.12) : Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _toggleStar(clip),
                  icon: Icon(
                    clip.isStarred ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 18,
                    color: clip.isStarred ? const Color(0xFFFBBF24) : Colors.white60,
                  ),
                  label: Text(
                    clip.isStarred ? 'Starred' : 'Add to Star',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: clip.isStarred ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),

                // Note Button
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: hasNotes ? const Color(0xFF34D399) : Colors.white70,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: hasNotes ? const Color(0xFF10B981).withOpacity(0.12) : Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _openNoteEditor(clip),
                  icon: Icon(
                    hasNotes ? Icons.edit_note_rounded : Icons.note_add_outlined,
                    size: 18,
                    color: hasNotes ? const Color(0xFF34D399) : Colors.white60,
                  ),
                  label: Text(
                    hasNotes ? 'Edit Note' : 'Add Note',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),

                // Copy Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRecentlyCopied ? const Color(0xFF059669) : const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _copyClip(clip),
                  icon: Icon(
                    isRecentlyCopied ? Icons.check_rounded : Icons.copy_rounded,
                    size: 14,
                  ),
                  label: Text(
                    isRecentlyCopied ? 'Copied!' : 'Copy',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),

                // Share Button
                IconButton(
                  tooltip: 'Share',
                  icon: const Icon(Icons.share_rounded, size: 17, color: Colors.white60),
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  onPressed: () => _shareClip(clip),
                ),

                // Delete Button
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFF87171)),
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  onPressed: () => _confirmDelete(clip),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
