import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/account_state.dart';

class SupabaseService {
  static const String supabaseUrl = "https://hkcqjbbpmbvsabqnmqtb.supabase.co";
  static const String supabaseAnonKey =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhrY3FqYmJwbWJ2c2FicW5tcXRiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI5OTU0NDIsImV4cCI6MjEwODU3MTQ0Mn0.E0epekOwtIbickXC47nKZtQFRN5fo6ZzVTpqALzOIjw";

  static const String _accountCacheKey = 'lenscopy_account_cache';
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient? _client;
  AccountState _currentAccount = AccountState(accountId: 'mobile_guest');
  AccountState get account => _currentAccount;

  Future<void> init() async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      _client = Supabase.instance.client;
    } catch (e) {
      // Offline fallback
    }

    await _loadCachedAccount();
    // Auto-sync in background when app launches
    autoSync();
  }

  Future<void> _loadCachedAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_accountCacheKey);
    if (jsonStr != null) {
      _currentAccount = AccountState.fromMap(jsonDecode(jsonStr));
    } else {
      final newId = 'act_mob_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
      _currentAccount = AccountState(accountId: newId);
      await _saveCachedAccount();
    }
  }

  Future<void> _saveCachedAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accountCacheKey, jsonEncode(_currentAccount.toMap()));
  }

  /// Automatically provisions a free license if unactivated
  Future<void> autoRegisterFreeUser() async {
    if (_client == null || _currentAccount.isActivated) return;

    try {
      final response = await _client!.rpc('register_or_activate_extension_account', params: {
        'p_account_id': _currentAccount.accountId,
        'p_display_name': 'LensCopy Mobile User',
        'p_email': null,
        'p_license_key': null,
        'p_invite_code': null,
      });

      if (response != null && response['success'] == true) {
        _currentAccount = AccountState(
          isActivated: true,
          isPremium: response['is_premium'] ?? false,
          accountId: _currentAccount.accountId,
          displayName: 'LensCopy Mobile User',
          inviteCode: response['invite_code'],
          inviteLink: response['invite_link'] ?? 'https://lenscopy.app/invite/${response['invite_code']}',
          todayScans: response['usage_scans_today'] ?? 0,
          dailyAllowance: response['daily_scan_allowance'] ?? 15,
          daysRemaining: response['days_remaining'] ?? 0,
          referralCount: response['referral_count'] ?? 0,
        );
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
      _currentAccount = AccountState(
        isActivated: true,
        isPremium: response['is_premium'] ?? false,
        accountId: _currentAccount.accountId,
        displayName: displayName,
        email: email,
        licenseKey: licenseKey,
        inviteCode: response['invite_code'],
        inviteLink: response['invite_link'] ?? 'https://lenscopy.app/invite/${response['invite_code']}',
        todayScans: response['usage_scans_today'] ?? 0,
        dailyAllowance: response['daily_scan_allowance'] ?? 15,
        daysRemaining: response['days_remaining'] ?? 0,
        referralCount: response['referral_count'] ?? 0,
      );
      await _saveCachedAccount();
      return response;
    } else {
      throw Exception(response?['error'] ?? 'Activation failed');
    }
  }

  /// Sync local scan counts and check license renewal/resets
  Future<void> autoSync({int scanIncrement = 0}) async {
    if (_client == null) return;
    if (!_currentAccount.isActivated) {
      await autoRegisterFreeUser();
    }

    try {
      final response = await _client!.rpc('sync_extension_usage_and_license', params: {
        'p_account_id': _currentAccount.accountId,
        'p_scans_increment': scanIncrement,
      });

      if (response != null && response['success'] == true) {
        _currentAccount = AccountState(
          isActivated: true,
          isPremium: response['is_premium'] ?? false,
          accountId: _currentAccount.accountId,
          displayName: _currentAccount.displayName,
          email: _currentAccount.email,
          licenseKey: _currentAccount.licenseKey,
          inviteCode: response['invite_code'] ?? _currentAccount.inviteCode,
          inviteLink: _currentAccount.inviteLink,
          todayScans: response['usage_scans_today'] ?? _currentAccount.todayScans,
          dailyAllowance: response['daily_scan_allowance'] ?? 15,
          daysRemaining: response['days_remaining'] ?? _currentAccount.daysRemaining,
          referralCount: response['referral_count'] ?? _currentAccount.referralCount,
        );
        await _saveCachedAccount();
      }
    } catch (e) {
      // Offline fallback
    }
  }

  /// Record scan locally, checking quota
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
      todayScans: _currentAccount.todayScans + 1,
      dailyAllowance: _currentAccount.dailyAllowance,
      daysRemaining: _currentAccount.daysRemaining,
      referralCount: _currentAccount.referralCount,
    );
    await _saveCachedAccount();

    // Auto-sync scan with server in background
    autoSync(scanIncrement: 1);
    return true;
  }
}
