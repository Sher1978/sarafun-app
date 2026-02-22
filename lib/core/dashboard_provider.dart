import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sara_fun/core/providers.dart';
import 'package:sara_fun/models/user_model.dart';

class MasterStats {
  final int profileViews;
  final int totalLeads;
  final double conversionRate;
  final double monthlyEarnings;

  MasterStats({
    this.profileViews = 0,
    this.totalLeads = 0,
    this.conversionRate = 0.0,
    this.monthlyEarnings = 0.0,
  });
}

final masterStatsProvider = StreamProvider.autoDispose<MasterStats>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null || user.role != UserRole.master) {
    return Stream.value(MasterStats());
  }

  final firebaseService = ref.read(firebaseServiceProvider);

  // Combine streams for views, leads, and earnings
  final viewsStream = firebaseService.getProfileViews(user.uid);
  final leadsStream = firebaseService.getLeadsCount(user.uid);
  final earningsStream = firebaseService.getMonthlyEarnings(user.uid);

  return viewsStream.asyncMap((views) async {
    final leads = await leadsStream.first;
    final earnings = await earningsStream.first;
    
    // Simple conversion rate if we had profile views properly tracked
    final conversion = views > 0 ? (leads / views) * 100 : 0.0;

    return MasterStats(
      profileViews: views,
      totalLeads: leads,
      conversionRate: conversion,
      monthlyEarnings: earnings.toDouble(),
    );
  });
});

// Since statistics are often computed from deals/leads, we can also use a more 
// robust StreamZip or RxDart if available, but for now simple asyncMap is okay.
