enum UserRole { client, master, admin }

class AppUser {
  final String uid;
  final int telegramId;
  final String? username;
  final String? displayName;
  final String? photoURL;
  final String? phoneNumber;
  final UserRole role;
  
  // Wallet & Status
  final num balanceStars;
  final num depositBalance;
  final bool isVip;
  final int dealCountMonthly;

  // Business / Master Fields
  final String? businessName;
  final String? businessCategoryId;
  final double rating;
  final int reviewCount;
  final bool isVisible;
  
  // Location
  final double? latitude;
  final double? longitude;
  final String? city;

  // Referral System
  final String? referrerId;
  final List<String> referralPath;
  final String? businessRecommenderId;
  final String? businessOpenerId;

  // Favorites
  final List<String> favoriteServices;
  final List<String> favoriteMasters;

  final bool onboardingComplete;

  const AppUser({
    required this.uid,
    required this.telegramId,
    this.username,
    this.displayName,
    this.photoURL,
    this.phoneNumber,
    this.role = UserRole.client,
    this.balanceStars = 0,
    this.depositBalance = 0,
    this.isVip = false,
    this.dealCountMonthly = 0,
    this.businessName,
    this.businessCategoryId,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isVisible = true,
    this.latitude,
    this.longitude,
    this.city,
    this.referrerId,
    this.referralPath = const [],
    this.businessRecommenderId,
    this.businessOpenerId,
    this.favoriteServices = const [],
    this.favoriteMasters = const [],
    this.onboardingComplete = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'telegramId': telegramId,
      'username': username,
      'displayName': displayName,
      'photoURL': photoURL,
      'phoneNumber': phoneNumber,
      'role': role.name,
      'balanceStars': balanceStars,
      'depositBalance': depositBalance,
      'isVip': isVip,
      'dealCountMonthly': dealCountMonthly,
      'businessName': businessName,
      'businessCategoryId': businessCategoryId,
      'rating': rating,
      'reviewCount': reviewCount,
      'isVisible': isVisible,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'referrerId': referrerId,
      'referralPath': referralPath,
      'businessRecommenderId': businessRecommenderId,
      'businessOpenerId': businessOpenerId,
      'favoriteServices': favoriteServices,
      'favoriteMasters': favoriteMasters,
      'onboardingComplete': onboardingComplete,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String? ?? '',
      telegramId: (map['telegramId'] as num?)?.toInt() ?? 0,
      username: map['username'] as String?,
      displayName: map['displayName'] as String?,
      photoURL: map['photoURL'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      role: _parseRole(map['role']),
      balanceStars: map['balanceStars'] as num? ?? 0,
      depositBalance: map['depositBalance'] as num? ?? 0,
      isVip: map['isVip'] as bool? ?? false,
      dealCountMonthly: (map['dealCountMonthly'] as num?)?.toInt() ?? 0,
      businessName: map['businessName'] as String?,
      businessCategoryId: map['businessCategoryId'] as String?,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      isVisible: map['isVisible'] as bool? ?? true,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      city: map['city'] as String?,
      referrerId: map['referrerId'] as String?,
      referralPath: List<String>.from(map['referralPath'] ?? []),
      businessRecommenderId: map['businessRecommenderId'] as String?,
      businessOpenerId: map['businessOpenerId'] as String?,
      favoriteServices: List<String>.from(map['favoriteServices'] ?? []),
      favoriteMasters: List<String>.from(map['favoriteMasters'] ?? []),
      onboardingComplete: map['onboardingComplete'] as bool? ?? false,
    );
  }

  static UserRole _parseRole(String? roleStr) {
    if (roleStr == 'master') return UserRole.master;
    if (roleStr == 'admin') return UserRole.admin;
    return UserRole.client;
  }

  AppUser copyWith({
    String? uid,
    int? telegramId,
    String? username,
    String? displayName,
    String? photoURL,
    String? phoneNumber,
    UserRole? role,
    num? balanceStars,
    num? depositBalance,
    bool? isVip,
    int? dealCountMonthly,
    String? businessName,
    String? businessCategoryId,
    double? rating,
    int? reviewCount,
    bool? isVisible,
    bool? isMapVisible,
    double? latitude,
    double? longitude,
    String? city,
    String? referrerId,
    List<String>? referralPath,
    String? businessRecommenderId,
    String? businessOpenerId,
    List<String>? favoriteServices,
    List<String>? favoriteMasters,
    bool? onboardingComplete,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      telegramId: telegramId ?? this.telegramId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      balanceStars: balanceStars ?? this.balanceStars,
      depositBalance: depositBalance ?? this.depositBalance,
      isVip: isVip ?? this.isVip,
      dealCountMonthly: dealCountMonthly ?? this.dealCountMonthly,
      businessName: businessName ?? this.businessName,
      businessCategoryId: businessCategoryId ?? this.businessCategoryId,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isVisible: isVisible ?? isMapVisible ?? this.isVisible,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      referrerId: referrerId ?? this.referrerId,
      referralPath: referralPath ?? this.referralPath,
      businessRecommenderId: businessRecommenderId ?? this.businessRecommenderId,
      businessOpenerId: businessOpenerId ?? this.businessOpenerId,
      favoriteServices: favoriteServices ?? this.favoriteServices,
      favoriteMasters: favoriteMasters ?? this.favoriteMasters,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }
}