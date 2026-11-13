import 'package:flutter/material.dart';

class LensActionPill extends StatefulWidget {
  final String selectedText;
  final bool isScanning;
  final VoidCallback onCopy;
  final VoidCallback onSelectAll;
  final VoidCallback onShare;
  final VoidCallback onSearch;
  final VoidCallback onClear;

  const LensActionPill({
    super.key,
    required this.selectedText,
    this.isScanning = false,
    required this.onCopy,
    required this.onSelectAll,
    required this.onShare,
    required this.onSearch,
    required this.onClear,
  });

  @override
  State<LensActionPill> createState() => _LensActionPillState();
}

class _LensActionPillState extends State<LensActionPill> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final text = widget.selectedText.trim();
    final hasSelection = text.isNotEmpty;
    final words = hasSelection ? text.split(RegExp(r'\s+')).length : 0;
    final chars = text.length;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.96),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.14), width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Live Selected Text Preview Area
          if (widget.isScanning)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: const [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF60A5FA)),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Deep Scanning text at high resolution...',
                    style: TextStyle(color: Color(0xFF93C5FD), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )
          else if (hasSelection)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 15),
                          const SizedBox(width: 6),
                          Text(
                            '$words words • $chars characters selected',
                            style: const TextStyle(
                              color: Color(0xFFA7F3D0),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () => setState(() => _isExpanded = !_isExpanded),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Row(
                            children: [
                              Text(
                                _isExpanded ? 'Collapse' : 'Expand',
                                style: const TextStyle(color: Color(0xFF818CF8), fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                              Icon(
                                _isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
                                size: 16,
                                color: const Color(0xFF818CF8),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: _isExpanded ? 160 : 54,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: SelectableText(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.35,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Action Buttons Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Primary Action Button (Copy Text or Select All)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: hasSelection ? widget.onCopy : widget.onSelectAll,
                    icon: Icon(
                      hasSelection ? Icons.copy_rounded : Icons.select_all_rounded,
                      size: 17,
                      color: Colors.white,
                    ),
                    label: Text(
                      hasSelection ? 'Copy Selected' : 'Select All Text',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),

                if (hasSelection) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.share_rounded, size: 20, color: Colors.white70),
                    tooltip: 'Share',
                    onPressed: widget.onShare,
                  ),
                  IconButton(
                    icon: const Icon(Icons.search_rounded, size: 22, color: Colors.white70),
                    tooltip: 'Search Web',
                    onPressed: widget.onSearch,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Colors.white54),
                    tooltip: 'Clear',
                    onPressed: widget.onClear,
                  ),
                ] else ...[
                  const SizedBox(width: 10),
                  Text(
                    'Tap words or drag box',
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
