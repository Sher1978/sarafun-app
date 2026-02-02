import 'package:equatable/equatable.dart';

enum UserRole { client, master }

class AppUser extends Equatable {
  final String uid;
  final int telegramId;
  final UserRole role;
  final String? referrerId;
  final List<String> referralPath; // Ancestors: [parent, grandparent, ...]
  final num balanceStars;
  final num depositBalance; // Only for Masters
  final bool isVip;
  final int dealCountMonthly;
  final bool isVisible; // Only for Masters
  final String? businessRecommenderId; // Master's recommender
  final String? businessOpenerId;      // Master's opener
  final double? latitude;
  final double? longitude;
  final bool isMapVisible;
  final String? displayName;
  final String? username;
  final String? businessName;

  const AppUser({
    required this.uid,
    required this.telegramId,
    required this.role,
    this.referrerId,
    this.referralPath = const [],
    this.balanceStars = 0,
    this.depositBalance = 0,
    this.isVip = false,
    this.dealCountMonthly = 0,
    this.isVisible = true,
    this.businessRecommenderId,
    this.businessOpenerId,
    this.latitude,
    this.longitude,
    this.isMapVisible = false,
    this.displayName,
    this.username,
    this.businessName,
  });

  @override
  List<Object?> get props => [
        uid,
        telegramId,
        role,
        referrerId,
        referralPath,
        balanceStars,
        depositBalance,
        isVip,
        dealCountMonthly,
        isVisible,
        businessRecommenderId,
        businessOpenerId,
        latitude,
        longitude,
        isMapVisible,
        displayName,
        username,
        businessName,
      ];

  AppUser copyWith({
    String? uid,
    int? telegramId,
    UserRole? role,
    String? referrerId,
    List<String>? referralPath,
    num? balanceStars,
    num? depositBalance,
    bool? isVip,
    int? dealCountMonthly,
    bool? isVisible,
    String? businessRecommenderId,
    String? businessOpenerId,
    double? latitude,
    double? longitude,
    bool? isMapVisible,
    String? displayName,
    String? username,
    String? businessName,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      telegramId: telegramId ?? this.telegramId,
      role: role ?? this.role,
      referrerId: referrerId ?? this.referrerId,
      referralPath: referralPath ?? this.referralPath,
      balanceStars: balanceStars ?? this.balanceStars,
      depositBalance: depositBalance ?? this.depositBalance,
      isVip: isVip ?? this.isVip,
      dealCountMonthly: dealCountMonthly ?? this.dealCountMonthly,
      isVisible: isVisible ?? this.isVisible,
      businessRecommenderId: businessRecommenderId ?? this.businessRecommenderId,
      businessOpenerId: businessOpenerId ?? this.businessOpenerId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isMapVisible: isMapVisible ?? this.isMapVisible,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      businessName: businessName ?? this.businessName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'telegramId': telegramId,
      'role': role.name,
      'referrerId': referrerId,
      'referralPath': referralPath,
      'balanceStars': balanceStars,
      'depositBalance': depositBalance,
      'isVip': isVip,
      'dealCountMonthly': dealCountMonthly,
      'isVisible': isVisible,
      'businessRecommenderId': businessRecommenderId,
      'businessOpenerId': businessOpenerId,
      'latitude': latitude,
      'longitude': longitude,
      'isMapVisible': isMapVisible,
      'displayName': displayName,
      'username': username,
      'businessName': businessName,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String,
      telegramId: map['telegramId'] as int,
      role: UserRole.values.firstWhere((e) => e.name == map['role']),
      referrerId: map['referrerId'] as String?,
      referralPath: List<String>.from(map['referralPath'] ?? []),
      balanceStars: (map['balanceStars'] as num? ?? 0),
      depositBalance: (map['depositBalance'] as num? ?? 0),
      isVip: map['isVip'] as bool? ?? false,
      dealCountMonthly: map['dealCountMonthly'] as int? ?? 0,
      isVisible: map['isVisible'] as bool? ?? true,
      businessRecommenderId: map['businessRecommenderId'] as String?,
      businessOpenerId: map['businessOpenerId'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      isMapVisible: map['isMapVisible'] as bool? ?? false,
      displayName: map['displayName'] as String?,
      username: map['username'] as String?,
      businessName: map['businessName'] as String?,
    );
  }
}
