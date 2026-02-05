
import 'package:flutter_test/flutter_test.dart';
import 'package:sara_fun/models/user_model.dart';
import 'package:sara_fun/services/referral_engine.dart';

void main() {
  group('ReferralEngine Logic Tests', () {
    const clientStandard = AppUser(
      uid: 'client1', 
      telegramId: 123, 
      role: UserRole.client, 
      balanceStars: 0, 
      depositBalance: 0, 
      isVip: false,
      dealCountMonthly: 0,
      referralPath: ['L1', 'L2', 'L3'],
    );

    final clientVip = clientStandard.copyWith(isVip: true);

    const master = AppUser(
      uid: 'master1', 
      telegramId: 456, 
      role: UserRole.master, 
      balanceStars: 0, 
      depositBalance: 1000, 
      isVip: false,
      dealCountMonthly: 0,
      businessRecommenderId: 'partner1',
      businessOpenerId: 'partner2',
      referralPath: [],
    );

    test('Standard Deal (100 Stars) - Full Chain', () {
      final dist = ReferralEngine.calculateDistribution(100, clientStandard, master);

      expect(dist.clientReward, 5.0, reason: "Standard Client should get 5%");
      expect(dist.l1Reward, 1.0, reason: "L1 should get 1%");
      expect(dist.l2Reward, 1.0, reason: "L2 should get 1%");
      expect(dist.l3Reward, 1.0, reason: "L3 should get 1%");
      expect(dist.recommenderReward, 2.0, reason: "Partner 1 should get 2%");
      expect(dist.openerReward, 2.0, reason: "Partner 2 should get 2%");
      
      // Total Deduced: 5 + 1+1+1 + 2+2 = 12.
      // Total Commission: 20.
      // Platform: 8.
      expect(dist.platformRevenue, 8.0, reason: "Platform should get remaining commission");
    });

    test('VIP Deal (100 Stars) - Full Chain', () {
      final dist = ReferralEngine.calculateDistribution(100, clientVip, master);

      expect(dist.clientReward, 10.0, reason: "VIP Client should get 10%");
      // Total Deduced: 10 + 3 + 4 = 17.
      // Platform: 3.
      expect(dist.platformRevenue, 3.0, reason: "Platform should get less on VIP deals");
    });

    test('Missing Referrers (Platform keeps share)', () {
      final clientNoRefs = clientStandard.copyWith(referralPath: []);
      final dist = ReferralEngine.calculateDistribution(100, clientNoRefs, master);

      expect(dist.clientReward, 5.0);
      expect(dist.l1Id, null);
      
      // Deductions: Client(5) + Partners(4) = 9.
      // Commission: 20.
      // Platform: 11. (Keeps the 3% from missing referrers)
      expect(dist.platformRevenue, 11.0);
    });

    test('Missing Partners (Platform keeps share)', () {
      const masterNoPartners = AppUser(
        uid: 'master1', 
        telegramId: 456, 
        role: UserRole.master, 
        balanceStars: 0, 
        depositBalance: 1000, 
        isVip: false,
        dealCountMonthly: 0,
        businessRecommenderId: null, // Explicitly null
        businessOpenerId: null,      // Explicitly null
        referralPath: [],
      );
      
      final dist = ReferralEngine.calculateDistribution(100, clientStandard, masterNoPartners);

      expect(dist.recommenderReward, 2.0); // Reward value is static calculation
      // But let's check platform revenue.
      // Deductions: Client(5) + Refs(3) = 8.
      // Partners are NOT deducted.
      // Commission: 20.
      // Platform: 12.
      
      expect(dist.platformRevenue, 12.0);
    });
  });
}
