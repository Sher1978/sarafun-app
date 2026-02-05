import 'package:flutter_test/flutter_test.dart';
import 'package:sara_fun/services/referral_engine.dart';
import 'package:sara_fun/models/user_model.dart';
import 'package:sara_fun/models/deal_model.dart';

void main() {
  group('ReferralEngine Tests', () {
    const double servicePrice = 1000.0; // 1000 Stars
    
    test('Distribution Calculation - Full Chain', () {
      // Setup: Client with full referral chain (L1, L2, L3)
      final client = const AppUser(
        uid: 'client', 
        telegramId: 1, 
        role: UserRole.client, 
        balanceStars: 0, 
        referralPath: ['l1_user', 'l2_user', 'l3_user']
      );

      final master = const AppUser(
        uid: 'master',
        telegramId: 2,
        role: UserRole.master,
        balanceStars: 1000,
        depositBalance: 500,
        isVisible: true,
        businessOpenerId: 'biz_open',
      );

      final deal = Deal(
        id: 'deal1',
        clientId: 'client',
        masterId: 'master',
        serviceId: 'svc',
        commissionDistribution: {}, 
        amountStars: servicePrice,
        status: DealStatus.completed, 
        createdAt: DateTime.now(), 
        commissionTotal: 200, // 20%
      );

      final distribution = ReferralEngine.calculateDistribution(deal.amountStars, client, master, businessRecommenderIdOverride: 'biz_rec');



      // Assertions based on Logic in source_of_truth / logic
      // Total Commission: 20% of 1000 = 200 Stars.
      
      // 1. Client Cashback (5% of 1000) = 50 Stars
      expect(distribution.clientReward, 50.0);

      // 2. L1 (1% of 1000) = 10 Stars
      expect(distribution.l1Reward, 10.0);

      // 3. L2 (1% of 1000) = 10 Stars
      expect(distribution.l2Reward, 10.0);

      // 4. L3 (1% of 1000) = 10 Stars
      expect(distribution.l3Reward, 10.0);

      // 5. Business Recommender (2% of 1000) = 20 Stars
      expect(distribution.recommenderReward, 20.0);

      // 6. Business Opener (2% of 1000) = 20 Stars
      expect(distribution.openerReward, 20.0);

      // 7. Platform Revenue (Remainder)
      // Distributed: 50 + 10 + 10 + 10 + 20 + 20 = 120 Stars.
      // Remainder: 200 - 120 = 80 Stars.
      expect(distribution.platformRevenue, 80.0);
    });

    test('Distribution Calculation - No Referrals', () {
      final client = const AppUser(
        uid: 'client', 
        telegramId: 1, 
        role: UserRole.client, 
        balanceStars: 0, 
        referralPath: [] // Empty
      );

      final master = const AppUser(
        uid: 'master',
        telegramId: 2,
        role: UserRole.master,
        balanceStars: 1000,
        depositBalance: 500,
        isVisible: true,
      );

      final deal = Deal(
        id: 'deal2',
        clientId: 'client',
        masterId: 'master',
        serviceId: 'svc',
        commissionDistribution: {},
        amountStars: servicePrice,
        status: DealStatus.completed, 
        createdAt: DateTime.now(), 
        commissionTotal: 200,
      );

      final distribution = ReferralEngine.calculateDistribution(deal.amountStars, client, master);

      // 1. Client Cashback (5% of 1000) = 50 Stars
      expect(distribution.clientReward, 50.0); // Always gets cashback

      // 2. L1, L2, L3 = 0
      expect(distribution.l1Reward, 0.0);
      expect(distribution.l2Reward, 0.0);
      expect(distribution.l3Reward, 0.0);

      // 3. Platform Revenue = 200 - 50 = 150 Stars
      expect(distribution.platformRevenue, 150.0);
    });
  });
}
