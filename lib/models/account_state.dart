class AccountState {
  final bool isActivated;
  final bool isPremium;
  final String accountId;
  final String displayName;
  final String? email;
  final String? licenseKey;
  final String? inviteCode;
  final String? inviteLink;
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
      'todayScans': todayScans,
      'dailyAllowance': dailyAllowance,
      'daysRemaining': daysRemaining,
      'referralCount': referralCount,
    };
  }

  factory AccountState.fromMap(Map<String, dynamic> map) {
    return AccountState(
      isActivated: map['isActivated'] ?? false,
      isPremium: map['isPremium'] ?? false,
      accountId: map['accountId'] ?? '',
      displayName: map['displayName'] ?? 'LensCopy Mobile User',
      email: map['email'],
      licenseKey: map['licenseKey'],
      inviteCode: map['inviteCode'],
      inviteLink: map['inviteLink'],
      todayScans: map['todayScans'] ?? 0,
      dailyAllowance: map['dailyAllowance'] ?? 15,
      daysRemaining: map['daysRemaining'] ?? 0,
      referralCount: map['referralCount'] ?? 0,
    );
  }
}
