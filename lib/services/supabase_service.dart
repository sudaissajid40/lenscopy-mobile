import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/account_state.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static const String _accountCacheKey = 'lenscopy_account_cache';
  static const String _supabaseUrl = 'https://hkcqjbbpmbvsabqnmqtb.supabase.co';
  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhrY3FqYmJwbWJ2c2FicW5tcXRiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEwNTkwMTgsImV4cCI6MjA3NjYzNTAxOH0.E_7Y9oP8WlWv5xQ8-U2vX-9d3g4j8z6s-1v2w3x4y5z';

  SupabaseClient? _client;
  AccountState _currentAccount = AccountState(accountId: '');

  AccountState get account => _currentAccount;

  Future<void> init() async {
    try {
      await Supabase.initialize(
        url: _supabaseUrl,
        anonKey: _supabaseAnonKey,
      );
      _client = Supabase.instance.client;
    } catch (e) {
      // Supabase already initialized or offline
      try {
        _client = Supabase.instance.client;
      } catch (_) {}
    }

    await _loadCachedAccount();
  }

  Future<void> _loadCachedAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_accountCacheKey);

    if (cached != null) {
      try {
        final map = jsonDecode(cached) as Map<String, dynamic>;
        _currentAccount = AccountState.fromMap(map);
      } catch (_) {}
    }

    if (_currentAccount.accountId.isEmpty) {
      final newId = 'lc_m_${DateTime.now().millisecondsSinceEpoch}_${_randomHex(6)}';
      _currentAccount = AccountState(accountId: newId);
      await _saveCachedAccount();
    }
  }

  Future<void> _saveCachedAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accountCacheKey, jsonEncode(_currentAccount.toMap()));
  }

  /// Automatically provisions or syncs user account with server
  Future<void> autoRegisterFreeUser({String? displayName, String? email, String? licenseKey, String? inviteCode}) async {
    if (_client == null) return;

    try {
      final response = await _client!.rpc('register_or_activate_extension_account', params: {
        'p_account_id': _currentAccount.accountId,
        'p_display_name': displayName ?? _currentAccount.displayName,
        'p_email': email ?? _currentAccount.email,
        'p_license_key': licenseKey ?? _currentAccount.licenseKey,
        'p_invite_code': inviteCode ?? _currentAccount.inviteCode,
      });

      if (response != null && response['success'] == true) {
        _currentAccount = AccountState.fromMap({
          ..._currentAccount.toMap(),
          ...Map<String, dynamic>.from(response),
          'accountId': _currentAccount.accountId,
          'displayName': displayName ?? response['display_name'] ?? _currentAccount.displayName,
          'email': email ?? response['email'] ?? _currentAccount.email,
          'licenseKey': licenseKey ?? response['license_key'] ?? _currentAccount.licenseKey,
          'inviteCode': response['invite_code'] ?? _currentAccount.inviteCode,
          'inviteLink': response['invite_link'] ?? 'https://lenscopy.app/invite/${response['invite_code']}',
          'dailyAllowance': response['daily_scan_allowance'] ?? response['dailyAllowance'] ?? 15,
        });
        await _saveCachedAccount();
      }
    } catch (e) {
      // Offline or network error
    }
  }

  /// Activate with a License Key or Invite Code
  Future<Map<String, dynamic>> activateLicense({
    required String displayName,
    String? email,
    String? licenseKey,
    String? inviteCode,
  }) async {
    if (_client == null) throw Exception('Network unavailable. Connect to internet to activate.');

    final response = await _client!.rpc('register_or_activate_extension_account', params: {
      'p_account_id': _currentAccount.accountId,
      'p_display_name': displayName,
      'p_email': email?.trim().isEmpty == true ? null : email?.trim(),
      'p_license_key': licenseKey?.trim().isEmpty == true ? null : licenseKey?.trim(),
      'p_invite_code': inviteCode?.trim().isEmpty == true ? null : inviteCode?.trim(),
    });

    if (response != null && response['success'] == true) {
      _currentAccount = AccountState.fromMap({
        ..._currentAccount.toMap(),
        ...Map<String, dynamic>.from(response),
        'accountId': _currentAccount.accountId,
        'displayName': displayName,
        'email': email,
        'licenseKey': licenseKey,
        'inviteCode': response['invite_code'],
        'inviteLink': response['invite_link'] ?? 'https://lenscopy.app/invite/${response['invite_code']}',
        'dailyAllowance': response['daily_scan_allowance'] ?? response['dailyAllowance'] ?? 15,
      });
      await _saveCachedAccount();
      return Map<String, dynamic>.from(response);
    } else {
      throw Exception(response?['error'] ?? 'License activation failed. Please check your key or internet.');
    }
  }

  /// Periodic sync with backend to refresh quota & license status
  Future<void> autoSync() async {
    if (_client == null) return;

    try {
      final response = await _client!.rpc('register_or_activate_extension_account', params: {
        'p_account_id': _currentAccount.accountId,
        'p_display_name': _currentAccount.displayName,
        'p_email': _currentAccount.email,
        'p_license_key': _currentAccount.licenseKey,
        'p_invite_code': null,
      });

      if (response != null && response['success'] == true) {
        _currentAccount = AccountState.fromMap({
          ..._currentAccount.toMap(),
          ...Map<String, dynamic>.from(response),
          'accountId': _currentAccount.accountId,
          'dailyAllowance': response['daily_scan_allowance'] ?? response['dailyAllowance'] ?? _currentAccount.dailyAllowance,
        });
        await _saveCachedAccount();
      }
    } catch (_) {
      // Offline fallback
    }
  }

  /// Record local scan usage & check limits
  Future<bool> recordScan() async {
    if (!_currentAccount.canScan) {
      return false;
    }

    _currentAccount = AccountState(
      isActivated: _currentAccount.isActivated,
      isPremium: _currentAccount.isPremium,
      accountId: _currentAccount.accountId,
      displayName: _currentAccount.displayName,
      email: _currentAccount.email,
      licenseKey: _currentAccount.licenseKey,
      inviteCode: _currentAccount.inviteCode,
      inviteLink: _currentAccount.inviteLink,
      premiumUntil: _currentAccount.premiumUntil,
      todayScans: _currentAccount.todayScans + 1,
      dailyAllowance: _currentAccount.dailyAllowance,
      daysRemaining: _currentAccount.daysRemaining,
      referralCount: _currentAccount.referralCount,
    );

    await _saveCachedAccount();

    // Async sync with Supabase
    autoSync().catchError((_) {});

    return true;
  }

  String _randomHex(int len) {
    const chars = '0123456789abcdef';
    final now = DateTime.now().microsecondsSinceEpoch.toString();
    return (now.length >= len) ? now.substring(now.length - len) : '1a2b3c';
  }
}
