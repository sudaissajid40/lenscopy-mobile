import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/clip_item.dart';

class ClipboardService {
  static const String _storageKey = 'lenscopy_clips_v1';
  static final ClipboardService _instance = ClipboardService._internal();
  factory ClipboardService() => _instance;
  ClipboardService._internal();

  List<ClipItem> _clips = [];
  List<ClipItem> get clips => List.unmodifiable(_clips);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_storageKey) ?? [];
    _clips = rawList.map((str) => ClipItem.fromJson(str)).toList();
    _sortClips();
  }

  void _sortClips() {
    _clips.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = _clips.map((c) => c.toJson()).toList();
    await prefs.setStringList(_storageKey, rawList);
  }

  /// Copy text to system clipboard and save to LensCopy Permanent Hub
  Future<ClipItem> copyAndSave(String text, {String source = 'Camera Scan'}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) throw Exception('Cannot copy empty text');

    // 1. Copy to System Clipboard
    await Clipboard.setData(ClipboardData(text: trimmed));

    // 2. Deduplicate or update existing
    final existingIdx = _clips.indexWhere((c) => c.text.trim() == trimmed);
    if (existingIdx != -1) {
      final existing = _clips.removeAt(existingIdx);
      final updated = ClipItem(
        id: existing.id,
        text: existing.text,
        source: source,
        createdAt: DateTime.now(),
        isPinned: existing.isPinned,
        category: existing.category,
      );
      _clips.insert(0, updated);
      _sortClips();
      await _saveToStorage();
      return updated;
    }

    final newClip = ClipItem(
      id: 'clip_${DateTime.now().millisecondsSinceEpoch}',
      text: trimmed,
      source: source,
      createdAt: DateTime.now(),
      isPinned: false,
      category: ClipItem.detectCategory(trimmed),
    );

    _clips.insert(0, newClip);
    _sortClips();
    await _saveToStorage();
    return newClip;
  }

  Future<void> togglePin(String id) async {
    final idx = _clips.indexWhere((c) => c.id == id);
    if (idx != -1) {
      _clips[idx].isPinned = !_clips[idx].isPinned;
      _sortClips();
      await _saveToStorage();
    }
  }

  /// Toggle star status
  Future<void> toggleStar(String id) => togglePin(id);

  /// Update personal notes attached to a scan
  Future<void> updateNotes(String id, String? notes) async {
    final idx = _clips.indexWhere((c) => c.id == id);
    if (idx != -1) {
      final cleanNotes = notes?.trim().isEmpty == true ? null : notes?.trim();
      _clips[idx] = _clips[idx].copyWith(notes: cleanNotes);
      await _saveToStorage();
    }
  }

  Future<void> deleteClip(String id) async {
    _clips.removeWhere((c) => c.id == id);
    await _saveToStorage();
  }

  Future<void> clearAll({bool keepPinned = true}) async {
    if (keepPinned) {
      _clips.removeWhere((c) => !c.isPinned);
    } else {
      _clips.clear();
    }
    await _saveToStorage();
  }

  List<ClipItem> filter({
    String query = '',
    String category = 'all',
    bool pinnedOnly = false,
    bool starredOnly = false,
    bool hasNotesOnly = false,
  }) {
    final q = query.trim().toLowerCase();
    return _clips.where((c) {
      if ((pinnedOnly || starredOnly) && !c.isStarred) return false;
      if (hasNotesOnly && (c.notes == null || c.notes!.trim().isEmpty)) return false;
      if (category != 'all' && c.category != category) return false;
      if (q.isNotEmpty) {
        final matchesText = c.text.toLowerCase().contains(q);
        final matchesNotes = (c.notes ?? '').toLowerCase().contains(q);
        if (!matchesText && !matchesNotes) return false;
      }
      return true;
    }).toList();
  }
}
