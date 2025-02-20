class UserProfile {
  final String userId;
  final String username;
  final String email;
  final String profilePictureUrl;
  final Map<String, dynamic>? tradingPreferences;
  final Map<String, dynamic>? watchlist;
  final String? phoneNumber;
  final String? address;
  final String? bankAccountNumber;
  final DateTime accountCreated;
  final DateTime lastLogin;
  final bool isVerified;
  final String tradingLevel; // 'beginner', 'intermediate', 'advanced'
  final double availableBalance;
  final List<String>? notifications;

  UserProfile({
    required this.userId,
    required this.username,
    required this.email,
    required this.profilePictureUrl,
    this.tradingPreferences,
    this.watchlist,
    this.phoneNumber,
    this.address,
    this.bankAccountNumber,
    DateTime? accountCreated,
    DateTime? lastLogin,
    this.isVerified = false,
    this.tradingLevel = 'beginner',
    this.availableBalance = 0.0,
    this.notifications,
  })  : accountCreated = accountCreated ?? DateTime.now(),
        lastLogin = lastLogin ?? DateTime.now();

  UserProfile copyWith({
    String? userId,
    String? username,
    String? email,
    String? profilePictureUrl,
    Map<String, dynamic>? tradingPreferences,
    Map<String, dynamic>? watchlist,
    String? phoneNumber,
    String? address,
    String? bankAccountNumber,
    DateTime? accountCreated,
    DateTime? lastLogin,
    bool? isVerified,
    String? tradingLevel,
    double? availableBalance,
    List<String>? notifications,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      tradingPreferences: tradingPreferences ?? this.tradingPreferences,
      watchlist: watchlist ?? this.watchlist,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      accountCreated: accountCreated ?? this.accountCreated,
      lastLogin: lastLogin ?? this.lastLogin,
      isVerified: isVerified ?? this.isVerified,
      tradingLevel: tradingLevel ?? this.tradingLevel,
      availableBalance: availableBalance ?? this.availableBalance,
      notifications: notifications ?? this.notifications,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'email': email,
      'profilePictureUrl': profilePictureUrl,
      'tradingPreferences': tradingPreferences,
      'watchlist': watchlist,
      'phoneNumber': phoneNumber,
      'address': address,
      'bankAccountNumber': bankAccountNumber,
      'accountCreated': accountCreated.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
      'isVerified': isVerified,
      'tradingLevel': tradingLevel,
      'availableBalance': availableBalance,
      'notifications': notifications,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'],
      username: json['username'],
      email: json['email'],
      profilePictureUrl: json['profilePictureUrl'],
      tradingPreferences: json['tradingPreferences'],
      watchlist: json['watchlist'],
      phoneNumber: json['phoneNumber'],
      address: json['address'],
      bankAccountNumber: json['bankAccountNumber'],
      accountCreated: DateTime.parse(json['accountCreated']),
      lastLogin: DateTime.parse(json['lastLogin']),
      isVerified: json['isVerified'],
      tradingLevel: json['tradingLevel'],
      availableBalance: json['availableBalance'].toDouble(),
      notifications: List<String>.from(json['notifications'] ?? []),
    );
  }

  bool canTrade() {
    return isVerified && bankAccountNumber != null;
  }

  bool hasCompletedProfile() {
    return phoneNumber != null && address != null && bankAccountNumber != null;
  }

  String getTradingLimitByLevel() {
    switch (tradingLevel) {
      case 'beginner':
        return '100000.00'; // ETB 100,000
      case 'intermediate':
        return '500000.00'; // ETB 500,000
      case 'advanced':
        return '1000000.00'; // ETB 1,000,000
      default:
        return '50000.00'; // ETB 50,000
    }
  }
}
