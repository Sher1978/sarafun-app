import 'package:sara_fun/models/user_model.dart';

class ReferralDistribution {
  final num clientReward;
  final num recommenderReward;
  final num openerReward;
  final num l1Reward;
  final num l2Reward;
  final num l3Reward;
  final num platformRevenue;

  // Recipient IDs
  final String? l1Id;
  final String? l2Id;
  final String? l3Id;
  final String? businessRecommenderId;
  final String? businessOpenerId;

  ReferralDistribution({
    required this.clientReward,
    required this.recommenderReward,
    required this.openerReward,
    required this.l1Reward,
    required this.l2Reward,
    required this.l3Reward,
    required this.platformRevenue,
    this.l1Id,
    this.l2Id,
    this.l3Id,
    this.businessRecommenderId,
    this.businessOpenerId,
  });

  factory ReferralDistribution.empty() {
    return ReferralDistribution(
      clientReward: 0,
      recommenderReward: 0,
      openerReward: 0,
      l1Reward: 0,
      l2Reward: 0,
      l3Reward: 0,
      platformRevenue: 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'client': clientReward,
      'recommender': recommenderReward,
      'opener': openerReward,
      'l1': l1Reward,
      'l2': l2Reward,
      'l3': l3Reward,
      'platform': platformRevenue,
      'l1Id': l1Id,
      'l2Id': l2Id,
      'l3Id': l3Id,
      'businessRecommenderId': businessRecommenderId,
      'businessOpenerId': businessOpenerId,
    };
  }
}

class ReferralEngine {
  /// Calculates the distribution of the 20% commission.
  static ReferralDistribution calculateDistribution(
    num amount,
    AppUser client,
    AppUser master, {
    String? businessRecommenderIdOverride,
  }) {
    final num totalCommission = amount * 0.20; // 20% Hard Cap
    num remainingCommission = totalCommission; // Platform gets what's left

    // 1. Client Cashback (5% or 10% for VIP)
    final int clientPercentage = client.isVip ? 10 : 5;
    final num clientReward = (amount * clientPercentage) / 100;
    remainingCommission -= clientReward;

    // 2. Business Partners (2% each)
    final num recommenderReward = (amount * 2) / 100;
    final num openerReward = (amount * 2) / 100;
    
    // Only deduct if IDs exist (logic handled in distribution object, but math assumes max potential deduction for safety, or we check existence?)
    // To match 'safety' we calculate potential, but let's check nulls for accuracy in 'platformRevenue'
    
    num deductedPartners = 0;
    if (businessRecommenderIdOverride != null || (master.businessRecommenderId?.isNotEmpty ?? false)) {
       deductedPartners += recommenderReward;
    }
    if (master.businessOpenerId?.isNotEmpty ?? false) {
       deductedPartners += openerReward;
    }
    remainingCommission -= deductedPartners;

    // 3. Referral Path (1% each for L1, L2, L3)
    final num l1Val = amount * 0.01;
    final num l2Val = amount * 0.01;
    final num l3Val = amount * 0.01;
    
    final l1Id = _getReferrerAt(client, 0);
    final l2Id = _getReferrerAt(client, 1);
    final l3Id = _getReferrerAt(client, 2);

    final l1Reward = l1Id != null ? l1Val : 0;
    final l2Reward = l2Id != null ? l2Val : 0;
    final l3Reward = l3Id != null ? l3Val : 0;

    remainingCommission -= l1Reward;
    remainingCommission -= l2Reward;
    remainingCommission -= l3Reward;

    final num platformRevenue = remainingCommission;
    
    // Also fix Recommender/Opener rewards in the return object? 
    // The previous logic calculated 'deductedPartners' but `recommenderReward` var was constant.
    // I should fix that too for consistency, but `recommenderReward` variable is used in `deductedPartners` calc above.
    // I will just return the CONDITIONAL rewards in the object.
    
    final String? recId = businessRecommenderIdOverride ?? master.businessRecommenderId;
    final String? opId = master.businessOpenerId;
    
    // We need to pass the conditionally zeroed rewards to constructor.
    // But constructor takes `recommenderReward`.
    // Let's recalculate them for the return object based on existence.
    
    return ReferralDistribution(
      clientReward: clientReward,
      recommenderReward: (recId != null && recId.isNotEmpty) ? recommenderReward : 0,
      openerReward: (opId != null && opId.isNotEmpty) ? openerReward : 0,

      l1Reward: l1Reward,
      l2Reward: l2Reward,
      l3Reward: l3Reward,
      platformRevenue: platformRevenue,
      l1Id: _getReferrerAt(client, 0),
      l2Id: _getReferrerAt(client, 1),
      l3Id: _getReferrerAt(client, 2),
      businessRecommenderId: businessRecommenderIdOverride ?? master.businessRecommenderId,
      businessOpenerId: master.businessOpenerId,
    );
  }

  static String? _getReferrerAt(AppUser user, int index) {
    if (index < user.referralPath.length) {
      final id = user.referralPath[index];
      return id.isEmpty ? null : id;
    }
    return null;
  }

  /// Checks if a master has enough deposit to cover the commission.
  static bool hasSufficientDeposit(AppUser master, num dealAmount) {
     final num requiredCommission = dealAmount * 0.20;
     return master.depositBalance >= requiredCommission;
  }

  /// Generates a Telegram deep link for referrals or services.
  static String generateDeepLink({String? referrerId, String? masterId, String? serviceId}) {
    // Format: https://t.me/YOUR_BOT/app?startapp=L1_CODE_REF2
    String parameter = "";
    if (serviceId != null) {
      parameter = "srv_$serviceId";
    } else if (masterId != null) {
      parameter = "biz_$masterId";
    } else if (referrerId != null) {
      parameter = "ref_$referrerId";
    }
    
    return "https://t.me/SaraFunDubaiBot/app?startapp=$parameter";
  }
}
