import 'dart:convert';

class ClipItem {
  final String id;
  final String text;
  final String source; // "Camera Scan", "Screen OCR", "Gallery Import"
  final DateTime createdAt;
  bool isPinned; // Starred / Pinned status
  final String category; // "all", "links", "emails", "code", "text"
  String? notes; // User personal notes / annotations for this scan

  bool get isStarred => isPinned;
  set isStarred(bool val) => isPinned = val;

  ClipItem({
    required this.id,
    required this.text,
    required this.source,
    required this.createdAt,
    this.isPinned = false,
    required this.category,
    this.notes,
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

  ClipItem copyWith({
    String? id,
    String? text,
    String? source,
    DateTime? createdAt,
    bool? isPinned,
    String? category,
    String? notes,
  }) {
    return ClipItem(
      id: id ?? this.id,
      text: text ?? this.text,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      isPinned: isPinned ?? this.isPinned,
      category: category ?? this.category,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'source': source,
      'createdAt': createdAt.toIso8601String(),
      'isPinned': isPinned,
      'isStarred': isPinned,
      'category': category,
      'notes': notes,
    };
  }

  factory ClipItem.fromMap(Map<String, dynamic> map) {
    return ClipItem(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      source: map['source'] ?? 'OCR Scan',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      isPinned: map['isStarred'] ?? map['isPinned'] ?? false,
      category: map['category'] ?? 'text',
      notes: map['notes'],
    );
  }

  String toJson() => jsonEncode(toMap());
  factory ClipItem.fromJson(String source) => ClipItem.fromMap(jsonDecode(source));
}
