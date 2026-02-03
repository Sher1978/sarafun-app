import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:sara_fun/models/review_model.dart';
import 'package:sara_fun/models/user_model.dart';
import 'package:sara_fun/models/deal_model.dart';
import 'package:sara_fun/models/service_card_model.dart';
import 'package:sara_fun/models/transaction_model.dart';
import 'package:sara_fun/services/referral_engine.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Auth ---
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithCustomToken(String token) async {
    return await _auth.signInWithCustomToken(token);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Sign in with Telegram using a Custom Token from Cloud Functions.
  Future<UserCredential> signInWithTelegram(String initData) async {
    try {
      final result = await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('authenticateTelegram')
          .call({'initData': initData});

      final String customToken = result.data['token'];
      return await _auth.signInWithCustomToken(customToken);
    } on FirebaseFunctionsException catch (e) {
      print('🔥 Firebase Functions Error:');
      print('🔥 CODE: ${e.code}');
      print('🔥 MSG: ${e.message}');
      print('🔥 DETAILS: ${e.details}');
      rethrow;
    } catch (e) {
      print("General Auth Error: $e");
      rethrow;
    }
  }

  // --- Users ---
  Future<void> saveUser(AppUser user) async {
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(user.toMap(), SetOptions(merge: true));
  }

  /// Syncs Telegram User profile with Firestore.
  /// Assumes user is already authenticated (via signInWithTelegram).
  Future<AppUser> syncTelegramUser(int telegramId, String firstName, String? username, {String? referrerId}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("User must be authenticated to sync profile");

    // 1. Check if user document exists (using uid as doc ID)
    final docRef = _firestore.collection('users').doc(uid);
    final doc = await docRef.get();

    if (doc.exists) {
      // User exists
      return AppUser.fromMap(doc.data()!);
    } else {
      // 2. Create new user using the current UID
      final newUser = AppUser(
        uid: uid,
        telegramId: telegramId,
        role: UserRole.client, // Default to client
        balanceStars: 0,
        depositBalance: 0,
        isVip: false,
        dealCountMonthly: 0,
        referrerId: referrerId,
        referralPath: [],
        displayName: firstName,
        username: username,
      );

      await saveUser(newUser);
      return newUser;
    }
  }

  Future<AppUser?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return AppUser.fromMap(doc.data()!);
    }
    return null;
  }


  // --- Service Cards ---
  Future<void> createServiceCard(ServiceCard card) async {
    await _firestore.collection('service_cards').add(card.toMap());
  }

  Stream<List<ServiceCard>> getServiceCardsStream(String masterId) {
    return _firestore
        .collection('service_cards')
        .where('master_id', isEqualTo: masterId)
        .orderBy('is_active', descending: true) // Active first
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ServiceCard.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Get ALL active service cards for Discovery
  Stream<List<ServiceCard>> getAllServiceCardsStream() {
    return _firestore
        .collection('service_cards')
        // .where('is_active', isEqualTo: true) // Ideally index this
        .orderBy('is_active', descending: true) 
        .limit(50) // Basic limit for MVP
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ServiceCard.fromMap(doc.data(), doc.id))
          .where((card) => card.isActive) // client-side filtering if index missing
          .toList();
    });
  }

  // --- Deals ---
  Future<void> createDeal(Deal deal) async {
    await _firestore.collection('deals').doc(deal.id).set(deal.toMap());
  }

  /// Executes the deal transaction: Creates Deal doc AND updates user balances with logs.
  Future<void> processDealTransaction(Deal deal, ReferralDistribution dist, AppUser client, AppUser master) async {
    final batch = _firestore.batch();
    final now = DateTime.now();

    // 1. Create Deal
    final dealRef = _firestore.collection('deals').doc(deal.id);
    batch.set(dealRef, deal.toMap());

    // 2. Deduct from Master (Total 20% commission)
    final masterRef = _firestore.collection('users').doc(master.uid);
    final num totalCommission = deal.amountStars * 0.20;
    
    batch.update(masterRef, {
      'depositBalance': FieldValue.increment(-totalCommission),
      'dealCountMonthly': FieldValue.increment(1),
    });

    // Master deduction log
    final masterTxRef = _firestore.collection('transactions').doc();
    batch.set(masterTxRef, {
      'id': masterTxRef.id,
      'userId': master.uid,
      'amount': totalCommission,
      'type': TransactionType.payment.name,
      'note': 'Commission for Deal ${deal.id}',
      'createdAt': now.toIso8601String(),
    });

    // 3. Reward Client (Cashback)
    final clientRef = _firestore.collection('users').doc(client.uid);
    batch.update(clientRef, {
      'balanceStars': FieldValue.increment(dist.clientReward),
      'dealCountMonthly': FieldValue.increment(1),
    });

    final clientTxRef = _firestore.collection('transactions').doc();
    batch.set(clientTxRef, {
      'id': clientTxRef.id,
      'userId': client.uid,
      'amount': dist.clientReward,
      'type': TransactionType.cashback.name,
      'note': 'Cashback for Deal ${deal.id}',
      'createdAt': now.toIso8601String(),
    });

    // 4. Client Referral Rewards (L1, L2, L3)
    final referralIds = [dist.l1Id, dist.l2Id, dist.l3Id];
    final referralRewards = [dist.l1Reward, dist.l2Reward, dist.l3Reward];
    final labels = ['L1', 'L2', 'L3'];

    for (int i = 0; i < 3; i++) {
        final id = referralIds[i];
        final reward = referralRewards[i];
        if (id != null && id.isNotEmpty && reward > 0) {
            batch.update(_firestore.collection('users').doc(id), {
                'balanceStars': FieldValue.increment(reward),
            });
            
            final txRef = _firestore.collection('transactions').doc();
            batch.set(txRef, {
              'id': txRef.id,
              'userId': id,
              'amount': reward,
              'type': TransactionType.referralBonus.name,
              'note': '${labels[i]} Referral Reward',
              'createdAt': now.toIso8601String(),
            });
        }
    }

    // 5. Business Agent Rewards (Recommender, Opener)
    if (dist.businessRecommenderId != null && dist.businessRecommenderId!.isNotEmpty && dist.recommenderReward > 0) {
        batch.update(_firestore.collection('users').doc(dist.businessRecommenderId!), {
            'balanceStars': FieldValue.increment(dist.recommenderReward),
        });
        
        final txRef = _firestore.collection('transactions').doc();
        batch.set(txRef, {
          'id': txRef.id,
          'userId': dist.businessRecommenderId!,
          'amount': dist.recommenderReward,
          'type': TransactionType.directBonus.name,
          'note': 'Direct Recommendation Bonus (2%)',
          'createdAt': now.toIso8601String(),
        });
    }

    if (dist.businessOpenerId != null && dist.businessOpenerId!.isNotEmpty && dist.openerReward > 0) {
        batch.update(_firestore.collection('users').doc(dist.businessOpenerId!), {
            'balanceStars': FieldValue.increment(dist.openerReward),
        });

        final txRef = _firestore.collection('transactions').doc();
        batch.set(txRef, {
          'id': txRef.id,
          'userId': dist.businessOpenerId!,
          'amount': dist.openerReward,
          'type': TransactionType.openerBonus.name,
          'note': 'Business Opener Bonus (2%)',
          'createdAt': now.toIso8601String(),
        });
    }

    await batch.commit();
  }

  Stream<List<Deal>> getDealsForUser(String uid, {bool isClient = true}) {
    final field = isClient ? 'clientId' : 'masterId';
    return _firestore
        .collection('deals')
        .where(field, isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Deal.fromMap(doc.data())).toList();
    });
  }

  /// Calculates and updates VIP status based on 10+ deals in last 30 days.
  /// Returns the updated user object.
  Future<AppUser> checkAndRefreshVipStatus(AppUser user) async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    // Query deals for this client in the last 30 days
    final query = await _firestore
        .collection('deals')
        .where('clientId', isEqualTo: user.uid)
        .where('createdAt', isGreaterThanOrEqualTo: thirtyDaysAgo.toIso8601String())
        .get();

    final dealCount = query.docs.length;
    final bool shouldBeVip = dealCount >= 10;

    if (user.isVip != shouldBeVip) {
      final updatedUser = user.copyWith(isVip: shouldBeVip, dealCountMonthly: dealCount);
      await saveUser(updatedUser);
      return updatedUser;
    }

    return user;
  }
  // --- Storage & Reviews ---
  Future<String?> uploadImage(Uint8List fileBytes, String path) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      await ref.putData(fileBytes);
      return await ref.getDownloadURL();
    } catch (e) {
      print("Upload Error: $e");
      return null;
    }
  }

  Future<void> submitReview(Review review) async {
    final batch = _firestore.batch();
    
    // 1. Create Review
    final reviewRef = _firestore.collection('reviews').doc(review.id);
    batch.set(reviewRef, review.toMap());

    // 2. Update Service Rating (Simple Average for MVP)
    // Ideally use Cloud Functions for atomic aggregation
    // Here we just save it; aggregation is query-time or manual for now
    
    await batch.commit();
  }

  Stream<List<Review>> getReviewsForService(String serviceId) {
    return _firestore
        .collection('reviews')
        .where('service_id', isEqualTo: serviceId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Review.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Stream<List<AppUser>> getDiscoveryMastersStream() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: UserRole.master.name)
        .where('isVisible', isEqualTo: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AppUser.fromMap(doc.data())).toList();
    });
  }

  Stream<List<AppUser>> getVisibleMastersOnMap() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: UserRole.master.name)
        .where('isMapVisible', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AppUser.fromMap(doc.data()))
          .where((user) => user.latitude != null && user.longitude != null)
          .toList();
    });
  }

  Future<void> updateUserLocation(String uid, {double? lat, double? lng, bool? isMapVisible}) async {
    final Map<String, dynamic> updates = {};
    if (lat != null) updates['latitude'] = lat;
    if (lng != null) updates['longitude'] = lng;
    if (isMapVisible != null) updates['isMapVisible'] = isMapVisible;
    
    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(uid).update(updates);
    }
  }

  Future<void> upgradeToMaster(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'role': UserRole.master.name,
      'isVisible': true, // Keep isVisible true as it means "active master"
      'isMapVisible': false, // Hide from map until location configured
      'depositBalance': 0, // Set initial deposit balance to 0 as per final task
    });
  }

  Stream<List<Transaction>> getTransactionsStream(String uid) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Transaction.fromMap(doc.data())).toList().cast<Transaction>();
    });
  }

  Future<void> toggleFavorite(String uid, String itemId, bool isService) async {
    final userRef = _firestore.collection('users').doc(uid);
    final doc = await userRef.get();
    if (!doc.exists) return;

    final user = AppUser.fromMap(doc.data()!);
    final field = isService ? 'favoriteServices' : 'favoriteMasters';
    final List<String> currentList = List<String>.from(doc.data()![field] ?? []);

    if (currentList.contains(itemId)) {
      currentList.remove(itemId);
    } else {
      currentList.add(itemId);
    }

    await userRef.update({field: currentList});
  }
}
