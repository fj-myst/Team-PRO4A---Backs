import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new announcement
  Future<Map<String, dynamic>> createAnnouncement({
    required String title,
    required String authority,
    required String toPreside,
    required String attendeeType,
    required List<String> attendeeUnitIds,
    required Map<String, String> specificPersonnelPerUnit,
    required String invitedOrganizations,
    required String invitedNames,
    required List<String> agendaItems,
    required DateTime dateTime,
    required String venueId,
    required String venueName,
    required bool needsTechAssist,
    required String tasks,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {'success': false, 'message': 'Not logged in.'};
      }

      // ✅ fetch creator's name from users collection
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final createdByName = userDoc.data()?['name'] ?? 'Unknown';

      final List<String> visibleTo = [...attendeeUnitIds];

      await _firestore.collection('announcements').add({
        'title': title,
        'authority': authority,
        'toPreside': toPreside,
        'attendeeType': attendeeType,
        'attendeeUnitIds': attendeeUnitIds,
        'specificPersonnelPerUnit': specificPersonnelPerUnit,
        'invitedOrganizations': invitedOrganizations,
        'invitedNames': invitedNames,
        'agendaItems': agendaItems,
        'dateTime': Timestamp.fromDate(dateTime),
        'venueId': venueId,
        'venueName': venueName,
        'needsTechAssist': needsTechAssist,
        'tasks': tasks,
        'visibleTo': visibleTo,
        'createdBy': currentUser.uid,
        'createdByName': createdByName,       // ✅ ADDED
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Get all active venues
  Future<List<Map<String, dynamic>>> getVenues() async {
    try {
      final snapshot = await _firestore
          .collection('venues')
          .where('isActive', isEqualTo: true)
          .get();
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get all active units
  Future<List<Map<String, dynamic>>> getUnits() async {
    try {
      final snapshot = await _firestore
          .collection('units')
          .where('isActive', isEqualTo: true)
          .get();
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get all active personnel
  Future<List<Map<String, dynamic>>> getPersonnel() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'personnel')
          .where('isActive', isEqualTo: true)
          .get();
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get announcements created by current user
  Future<List<Map<String, dynamic>>> getMyAnnouncements() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      final snapshot = await _firestore
          .collection('announcements')
          .where('createdBy', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Delete announcement
  Future<Map<String, dynamic>> deleteAnnouncement(
      String announcementId) async {
    try {
      await _firestore
          .collection('announcements')
          .doc(announcementId)
          .delete();
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Update announcement
  Future<Map<String, dynamic>> updateAnnouncement({
    required String announcementId,
    required String title,
    required String authority,
    required String toPreside,
    required String attendeeType,
    required List<String> attendeeUnitIds,
    required Map<String, String> specificPersonnelPerUnit,
    required String invitedOrganizations,
    required String invitedNames,
    required List<String> agendaItems,
    required DateTime dateTime,
    required String venueId,
    required String venueName,
    required bool needsTechAssist,
    required String tasks,
  }) async {
    try {
      final List<String> visibleTo = [...attendeeUnitIds];

      await _firestore
          .collection('announcements')
          .doc(announcementId)
          .update({
        'title': title,
        'authority': authority,
        'toPreside': toPreside,
        'attendeeType': attendeeType,
        'attendeeUnitIds': attendeeUnitIds,
        'specificPersonnelPerUnit': specificPersonnelPerUnit,
        'invitedOrganizations': invitedOrganizations,
        'invitedNames': invitedNames,
        'agendaItems': agendaItems,
        'dateTime': Timestamp.fromDate(dateTime),
        'venueId': venueId,
        'venueName': venueName,
        'needsTechAssist': needsTechAssist,
        'tasks': tasks,
        'visibleTo': visibleTo,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Get announcements where current user's unit is in visibleTo (News Feed)
  Future<List<Map<String, dynamic>>> getNewsFeed() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      final unitQuery = await _firestore
          .collection('units')
          .where('email', isEqualTo: currentUser.email)
          .limit(1)
          .get();

      if (unitQuery.docs.isEmpty) return [];

      final unitDocId = unitQuery.docs.first.id;

      final snapshot = await _firestore
          .collection('announcements')
          .where('visibleTo', arrayContains: unitDocId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTechAdminFeed() async {
  try {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    // Query 1: announcements where Tech Admin's unit doc is in visibleTo
    final taggedSnapshot = await _firestore
        .collection('announcements')
        .where('visibleTo', arrayContains: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .get();

    // Query 2: announcements that need tech assistance
    final techSnapshot = await _firestore
        .collection('announcements')
        .where('needsTechAssist', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .get();

    // Merge and deduplicate by doc ID
    final Map<String, Map<String, dynamic>> merged = {};

    for (var doc in taggedSnapshot.docs) {
      merged[doc.id] = {'id': doc.id, ...doc.data()};
    }
    for (var doc in techSnapshot.docs) {
      merged[doc.id] = {'id': doc.id, ...doc.data()};
    }

    // Sort merged results by dateTime descending
    final result = merged.values.toList();
    result.sort((a, b) {
      final aTime = a['createdAt'];
      final bTime = b['createdAt'];
      if (aTime == null || bTime == null) return 0;
      return (bTime as Timestamp).compareTo(aTime as Timestamp);
    });

    return result;
  } catch (e) {
    return [];
  }
}

}