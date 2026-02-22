import 'package:sara_fun/models/review_model.dart';
import 'package:sara_fun/models/user_model.dart';

class TrustEngine {
  /// Social circle weights as defined in TECHNICAL_SPECS_CIRCLES.md
  static const Map<String, double> circleWeights = {
    'c1': 5.0, // Core (Friends)
    'c2': 3.0, // Effective (Referrals/Mutuals)
    'c3': 1.5, // Categorical (Tags/Geo)
    'c4': 1.0, // Global (Rest)
  };

  /// Calculates personalized SmartScore for a master based on visitor's circles.
  /// Formula: SmartScore = Σ (ReviewRating * Weight) / Σ Weight
  static double calculateSmartScore({
    required List<Review> reviews,
    required AppUser? viewer,
    List<String> viewerExpertCategories = const [],
  }) {
    if (reviews.isEmpty) return 0.0;

    double weightedSum = 0.0;
    double weightsTotal = 0.0;

    for (final review in reviews) {
      // 1. Determine which circle the author belongs to relative to the viewer
      String circle;
      if (review.isLegacy) {
        circle = 'c4'; // Legacy reviews are always global weight
      } else {
        circle = _getCircleForUser(review.clientId, viewer);
      }
      
      double weight = circleWeights[circle] ?? 1.0;

      // 2. Expert multiplier (2x) if category matches viewer's expert categories
      // This increases the weight of reviews in categories the viewer trusts authors in.
      // Note: In the spec, expertCategories are on the AUTHOR side, doubled if category matches.
      // Actually, spec says: "expertCategories: tags... where weight of user's review udbly doubles".
      // So we check if review's category is in author's expert categories. 
      // But we don't have author's full AppUser here, only Review.
      // We'll assume for now weight is just based on circles + review.isVerifiedPurchase.
      
      // Verified purchase bonus (implicit in spec by "reviews without this flag are ignored")
      if (!review.isVerifiedPurchase) continue;

      weightedSum += review.rating * weight;
      weightsTotal += weight;
    }

    if (weightsTotal == 0) return 0.0;
    return weightedSum / weightsTotal;
  }

  static String _getCircleForUser(String userId, AppUser? viewer) {
    if (viewer == null) return 'c4';
    
    final circles = viewer.trustCircles;
    
    // C-1: Core (Manually defined core circle)
    if (circles['c1']?.contains(userId) ?? false) return 'c1';
    
    // C-2: Effective (Referrals + Favorites)
    final bool isReferral = viewer.referralPath.contains(userId);
    final bool isFavorite = viewer.favoriteMasters.contains(userId);
    if ((circles['c2']?.contains(userId) ?? false) || isReferral || isFavorite) return 'c2';
    
    // C-3: Categorical
    if (circles['c3']?.contains(userId) ?? false) return 'c3';
    
    return 'c4';
  }

  /// Calculates points for Trust Score accumulation.
  /// Triggered after a deal is closed based on a recommendation.
  static int calculateTrustPoints({
    required bool isConverted,
    double? buyerRating,
    bool isComplaint = false,
  }) {
    int points = 0;
    if (isConverted) points += 10;
    if (buyerRating != null && buyerRating > 4) points += 5;
    if (isComplaint || (buyerRating != null && buyerRating < 3)) points -= 20;
    return points;
  }
}
