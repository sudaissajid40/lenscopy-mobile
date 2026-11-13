class AccountState {
  final bool isActivated;
  final bool isPremium;
  final String accountId;
  final String displayName;
  final String? email;
  final String? licenseKey;
  final String? inviteCode;
  final String? inviteLink;
  final DateTime? premiumUntil;
  final int todayScans;
  final int dailyAllowance;
  final int daysRemaining;
  final int referralCount;

  AccountState({
    this.isActivated = false,
    this.isPremium = false,
    required this.accountId,
    this.displayName = 'LensCopy Mobile User',
    this.email,
    this.licenseKey,
    this.inviteCode,
    this.inviteLink,
    this.premiumUntil,
    this.todayScans = 0,
    this.dailyAllowance = 15,
    this.daysRemaining = 0,
    this.referralCount = 0,
  });

  bool get canScan => isPremium || (todayScans < dailyAllowance);
  int get remainingScans => isPremium ? -1 : (dailyAllowance - todayScans).clamp(0, dailyAllowance);

  Map<String, dynamic> toMap() {
    return {
      'isActivated': isActivated,
      'isPremium': isPremium,
      'accountId': accountId,
      'displayName': displayName,
      'email': email,
      'licenseKey': licenseKey,
      'inviteCode': inviteCode,
      'inviteLink': inviteLink,
      'premiumUntil': premiumUntil?.toIso8601String(),
      'todayScans': todayScans,
      'dailyAllowance': dailyAllowance,
      'daysRemaining': daysRemaining,
      'referralCount': referralCount,
    };
  }

  factory AccountState.fromMap(Map<String, dynamic> map) {
    DateTime? parsedExpiry;
    if (map['premiumUntil'] != null) {
      parsedExpiry = DateTime.tryParse(map['premiumUntil'].toString());
    } else if (map['premium_until'] != null) {
      parsedExpiry = DateTime.tryParse(map['premium_until'].toString());
    }

    int computedDays = 0;
    bool computedPremium = map['isPremium'] ?? map['is_premium'] ?? false;

    if (parsedExpiry != null) {
      final diff = parsedExpiry.difference(DateTime.now());
      if (!diff.isNegative && diff.inSeconds > 0) {
        // Round up remaining days so a 2-day pass accurately shows 2 days remaining
        computedDays = (diff.inSeconds / 86400.0).ceil();
        computedPremium = true;
      } else {
        computedDays = 0;
        computedPremium = false;
      }
    } else if (map['daysRemaining'] != null && map['daysRemaining'] > 0) {
      computedDays = map['daysRemaining'];
      computedPremium = true;
    }

    return AccountState(
      isActivated: map['isActivated'] ?? map['is_activated'] ?? false,
      isPremium: computedPremium,
      accountId: map['accountId'] ?? map['account_id'] ?? '',
      displayName: map['displayName'] ?? map['display_name'] ?? 'LensCopy Mobile User',
      email: map['email'],
      licenseKey: map['licenseKey'] ?? map['license_key'],
      inviteCode: map['inviteCode'] ?? map['invite_code'],
      inviteLink: map['inviteLink'] ?? map['invite_link'],
      premiumUntil: parsedExpiry,
      todayScans: map['todayScans'] ?? map['usage_scans_today'] ?? 0,
      dailyAllowance: map['dailyAllowance'] ?? map['daily_scan_allowance'] ?? 15,
      daysRemaining: computedDays,
      referralCount: map['referralCount'] ?? map['referral_count'] ?? 0,
    );
  }
}
