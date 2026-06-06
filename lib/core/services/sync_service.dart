import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'isar_service.dart';
import 'firebase_service.dart';

class SyncService {
  SyncService._();
  static final instance = SyncService._();

  StreamSubscription? _sub;
  bool _syncing = false;
  bool _enabled = false;

  Future<void> init({bool enabled = false}) async {
    _enabled = enabled;
    if (!enabled) { debugPrint('🔒 Sync disabled (privacy-first)'); return; }
    _sub = Connectivity().onConnectivityChanged.listen((r) {
      if (r.contains(ConnectivityResult.wifi) || r.contains(ConnectivityResult.mobile)) sync();
    });
    debugPrint('🔄 Sync ready');
  }

  Future<void> sync() async {
    if (!_enabled || _syncing || !FirebaseService.isSignedIn) return;
    _syncing = true;
    try {
      await _push();
      await _pull();
      debugPrint('✅ Sync complete');
    } catch (e) {
      debugPrint('❌ Sync error: $e');
    } finally {
      _syncing = false;
    }
  }

  Future<void> _push() async {
    final unsynced = await IsarService.habits.filter().isSyncedEqualTo(false).findAll();
    for (final h in unsynced) {
      await FirebaseService.firestore.collection('habits').doc(h.habitId).set({
        'habitId': h.habitId, 'name': h.name, 'description': h.description,
        'emoji': h.emoji, 'currentStreak': h.currentStreak, 'longestStreak': h.longestStreak,
        'totalCompletions': h.totalCompletions, 'updatedAt': h.updatedAt.toIso8601String(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> _pull() async {
    final snapshot = await FirebaseService.firestore.collection('habits').get();
    for (final doc in snapshot.docs) {
      // Merge remote → local logic here
    }
  }

  void dispose() { _sub?.cancel(); }
}