import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _collection = 'notifications';

  // ─── Create ───────────────────────────────────────────────────────────────

  /// Batch-creates notifications for all recipients in [visibleTo] except
  /// the actor (creator or editor).
  /// [type] must be either 'mentioned' or 'announcement_edited'.
  static Future<void> createNotificationsForAnnouncement({
    required String announcementId,
    required String announcementTitle,
    required List<String> visibleTo,
    required String actorUid,
    required String actorName,
    required String type,
  }) async {
    if (visibleTo.isEmpty) return;

    final batch = _db.batch();
    final now = FieldValue.serverTimestamp();

    for (final uid in visibleTo) {
      if (uid == actorUid) continue;

      final docRef = _db.collection(_collection).doc();
      batch.set(docRef, {
        'recipientUid': uid,
        'type': type,
        'announcementId': announcementId,
        'announcementTitle': announcementTitle,
        'createdBy': actorUid,
        'createdByName': actorName,
        'isRead': false,
        'createdAt': now,
      });
    }

    await batch.commit();
  }

  // ─── Stream (real-time bell) ───────────────────────────────────────────────

  /// Streams all notifications for the current user, newest first.
  /// Used by NotificationBell to show the dropdown list.
  static Stream<List<Map<String, dynamic>>> streamForCurrentUser() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _db
        .collection(_collection)
        .where('recipientUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  /// Streams the count of unread notifications for the current user.
  /// Used by NotificationBell to show the badge number.
  static Stream<int> unreadCountStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _db
        .collection(_collection)
        .where('recipientUid', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ─── Mark as Read ─────────────────────────────────────────────────────────

  /// Marks all unread notifications for the current user as read.
  /// Called when the notification dropdown is opened.
  static Future<void> markAllAsRead() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final unread = await _db
        .collection(_collection)
        .where('recipientUid', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();

    if (unread.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ─── FCM Token ────────────────────────────────────────────────────────────

  /// Saves or updates the FCM token for the current user in Firestore.
  /// Called from AuthService after a successful login.
  static Future<void> saveToken(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db.collection('users').doc(uid).update({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Clears the FCM token on logout so stale pushes are not delivered.
  static Future<void> clearToken() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db.collection('users').doc(uid).update({
      'fcmToken': FieldValue.delete(),
    });
  }
}