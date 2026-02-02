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
    final num totalCommission = amount * 0.20;
    num remainingCommission = totalCommission;

    final int clientPercentage = client.isVip ? 10 : 5;
    final num clientReward = (amount * clientPercentage) / 100;
    remainingCommission -= clientReward;

    final num recommenderReward = (amount * 2) / 100;
    final num openerReward = (amount * 2) / 100;
    remainingCommission -= (recommenderReward + openerReward);

    final num l1Reward = amount / 100;
    final num l2Reward = amount / 100;
    final num l3Reward = amount / 100;
    remainingCommission -= (l1Reward + l2Reward + l3Reward);

    final num platformRevenue = remainingCommission;

    return ReferralDistribution(
      clientReward: clientReward,
      recommenderReward: recommenderReward,
      openerReward: openerReward,
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
}
