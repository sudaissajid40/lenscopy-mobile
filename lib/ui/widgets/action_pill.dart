import 'package:flutter/material.dart';

class LensActionPill extends StatelessWidget {
  final String selectedText;
  final VoidCallback onCopy;
  final VoidCallback onSelectAll;
  final VoidCallback onShare;
  final VoidCallback onSearch;
  final VoidCallback onClear;

  const LensActionPill({
    super.key,
    required this.selectedText,
    required this.onCopy,
    required this.onSelectAll,
    required this.onShare,
    required this.onSearch,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedText.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.95),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1-Tap Copy Button
          ElevatedButton.icon(
            onPressed: hasSelection ? onCopy : onSelectAll,
            icon: Icon(
              hasSelection ? Icons.copy_rounded : Icons.select_all_rounded,
              size: 18,
              color: Colors.white,
            ),
            label: Text(
              hasSelection ? 'Copy Text' : 'Select All',
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
          if (hasSelection) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.share_rounded, size: 20, color: Colors.white70),
              tooltip: 'Share',
              onPressed: onShare,
            ),
            IconButton(
              icon: const Icon(Icons.search_rounded, size: 22, color: Colors.white70),
              tooltip: 'Search Web',
              onPressed: onSearch,
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20, color: Colors.white54),
              tooltip: 'Clear',
              onPressed: onClear,
            ),
          ],
        ],
      ),
    );
  }
}
