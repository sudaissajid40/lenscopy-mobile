import 'dart:convert';

class ClipItem {
  final String id;
  final String text;
  final String source; // "Camera Scan", "Screen OCR", "Gallery Import"
  final DateTime createdAt;
  bool isPinned;
  final String category; // "all", "links", "emails", "code", "text"

  ClipItem({
    required this.id,
    required this.text,
    required this.source,
    required this.createdAt,
    this.isPinned = false,
    required this.category,
  });

  static String detectCategory(String text) {
    final trimmed = text.trim();
    if (RegExp(r'^(https?:\/\/|www\.)[^\s/$.?#].[^\s]*$', caseSensitive: false).hasMatch(trimmed) ||
        RegExp(r'https?:\/\/[^\s]+').hasMatch(trimmed)) {
      return 'links';
    }
    if (RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b').hasMatch(trimmed)) {
      return 'emails';
    }
    if (trimmed.contains('{') && trimmed.contains('}') ||
        trimmed.contains('def ') ||
        trimmed.contains('function') ||
        trimmed.contains('class ') ||
        trimmed.contains('const ') ||
        trimmed.contains('import ')) {
      return 'code';
    }
    return 'text';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'source': source,
      'createdAt': createdAt.toIso8601String(),
      'isPinned': isPinned,
      'category': category,
    };
  }

  factory ClipItem.fromMap(Map<String, dynamic> map) {
    return ClipItem(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      source: map['source'] ?? 'OCR Scan',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      isPinned: map['isPinned'] ?? false,
      category: map['category'] ?? 'text',
    );
  }

  String toJson() => jsonEncode(toMap());
  factory ClipItem.fromJson(String source) => ClipItem.fromMap(jsonDecode(source));
}
