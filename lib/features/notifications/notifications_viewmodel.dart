import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/notification_model.dart';

class NotificationsViewModel extends ChangeNotifier {
  NotificationsViewModel() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _subscribe(user.uid);
      } else {
        _notifSub?.cancel();
        notifications = [];
        notifyListeners();
      }
    });
  }

  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot>? _notifSub;

  List<NotificationModel> notifications = [];

  int get unreadCount => notifications.where((n) => !n.read).length;

  void _subscribe(String uid) {
    _notifSub?.cancel();
    _notifSub = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen(
      (snap) {
        notifications = snap.docs
            .map((d) => NotificationModel.fromFirestore(d))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        notifyListeners();
      },
      onError: (e) => debugPrint('[Notifications] stream error: $e'),
    );
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      debugPrint('[Notifications] markAsRead failed: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final unread = notifications.where((n) => !n.read).toList();
    if (unread.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final n in unread) {
      batch.update(
        FirebaseFirestore.instance.collection('notifications').doc(n.id),
        {'read': true},
      );
    }
    try {
      await batch.commit();
    } catch (e) {
      debugPrint('[Notifications] markAllAsRead failed: $e');
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _notifSub?.cancel();
    super.dispose();
  }
}
