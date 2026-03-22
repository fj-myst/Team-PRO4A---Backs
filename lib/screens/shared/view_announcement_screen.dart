import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app_theme.dart';

class ViewAnnouncementScreen extends StatefulWidget {
  final Map<String, dynamic> announcement;
  const ViewAnnouncementScreen({super.key, required this.announcement});

  // Static helper to show as dialog
  static void show(BuildContext context, Map<String, dynamic> announcement) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => ViewAnnouncementScreen(announcement: announcement),
    );
  }

  @override
  State<ViewAnnouncementScreen> createState() =>
      _ViewAnnouncementScreenState();
}

class _ViewAnnouncementScreenState extends State<ViewAnnouncementScreen> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // Map of unitId -> {name, isRead}
  Map<String, Map<String, dynamic>> _readReceipts = {};
  bool _loadingReceipts = false;
  bool _isCreator = false;

  @override
  void initState() {
    super.initState();
    _checkAndLoadReceipts();
  }

  Future<void> _checkAndLoadReceipts() async {
    final currentUid = _auth.currentUser?.uid;
    final createdBy = widget.announcement['createdBy'];

    // Only load receipts if the current user is the creator
    if (currentUid == null || currentUid != createdBy) return;

    setState(() {
      _isCreator = true;
      _loadingReceipts = true;
    });

    try {
      final announcementId = widget.announcement['id'];
      final attendeeUnitIds =
          List<String>.from(widget.announcement['attendeeUnitIds'] ?? []);

      if (attendeeUnitIds.isEmpty) {
        setState(() => _loadingReceipts = false);
        return;
      }

      // Fetch unit names
      final Map<String, String> unitNames = {};
      for (final unitId in attendeeUnitIds) {
        final unitDoc = await _db.collection('units').doc(unitId).get();
        if (unitDoc.exists) {
          unitNames[unitId] = unitDoc.data()?['name'] ?? unitId;
        } else {
          unitNames[unitId] = unitId;
        }
      }

      // Fetch notifications for this announcement to check isRead per unit
      final notifSnapshot = await _db
          .collection('notifications')
          .where('announcementId', isEqualTo: announcementId)
          .where('type', isEqualTo: 'mentioned')
          .get();

      // Build a map of recipientUid -> isRead
      final Map<String, bool> readByUid = {};
      for (final doc in notifSnapshot.docs) {
        final data = doc.data();
        final uid = data['recipientUid'] as String?;
        final isRead = data['isRead'] as bool? ?? false;
        if (uid != null) {
          // If any notification for this uid is read, mark as read
          readByUid[uid] = (readByUid[uid] ?? false) || isRead;
        }
      }

      // Build final receipts map using unit IDs
      // Unit doc ID == unit's Auth UID (as per architecture)
      final Map<String, Map<String, dynamic>> receipts = {};
      for (final unitId in attendeeUnitIds) {
        receipts[unitId] = {
          'name': unitNames[unitId] ?? unitId,
          'isRead': readByUid[unitId] ?? false,
        };
      }

      if (!mounted) return;
      setState(() {
        _readReceipts = receipts;
        _loadingReceipts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingReceipts = false);
    }
  }

  String _fmt(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final a = widget.announcement;
    final dateTime =
        a['dateTime'] != null ? (a['dateTime'] as Timestamp).toDate() : null;
    final needsTech = a['needsTechAssist'] == true;
    final agendaItems = List<String>.from(a['agendaItems'] ?? []);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 820),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── HEADER + X ──
              Row(children: [
                Expanded(
                  child: Text(a['title'] ?? '',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                  style:
                      IconButton.styleFrom(foregroundColor: Colors.grey),
                ),
              ]),

              // Tech badge
              if (needsTech) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.orange.withOpacity(0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.build_circle,
                          size: 14, color: Colors.orange),
                      SizedBox(width: 6),
                      Text('Tech Assistance Required',
                          style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // ── DETAILS ──
              _row('Authority', a['authority'] ?? '—'),
              _row('To Preside', a['toPreside'] ?? '—'),
              _row('Date & Time',
                  dateTime != null ? _fmt(dateTime) : '—'),
              _row('Venue', a['venueName'] ?? '—'),
              _row('Attendee Type', a['attendeeType'] ?? '—'),

              // ── AGENDA ──
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Agenda',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.grey)),
              const SizedBox(height: 8),
              ...agendaItems.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8, left: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                              color: AppTheme.primaryBlue,
                              borderRadius: BorderRadius.circular(12)),
                          child: Center(
                            child: Text('${e.key + 1}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(e.value)),
                      ],
                    ),
                  )),

              // Optional fields
              if ((a['invitedOrganizations'] ?? '').isNotEmpty) ...[
                const Divider(),
                _row('Invited Organizations',
                    a['invitedOrganizations']),
              ],
              if ((a['invitedNames'] ?? '').isNotEmpty) ...[
                const Divider(),
                _row('Invited Names', a['invitedNames']),
              ],
              if ((a['tasks'] ?? '').isNotEmpty) ...[
                const Divider(),
                _row('Tasks', a['tasks']),
              ],

              // ── READ RECEIPTS (creator only) ──
              if (_isCreator) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  'Seen by',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),
                _buildReadReceipts(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadReceipts() {
    if (_loadingReceipts) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Loading...',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }

    if (_readReceipts.isEmpty) {
      return const Text(
        'No recipients found.',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _readReceipts.entries.map((entry) {
        final name = entry.value['name'] as String;
        final isRead = entry.value['isRead'] as bool;

        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isRead
                ? Colors.green.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isRead
                  ? Colors.green.withOpacity(0.4)
                  : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isRead ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 13,
                color: isRead ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isRead ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 160,
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.grey)),
            ),
            Expanded(
                child:
                    Text(value, style: const TextStyle(fontSize: 13))),
          ],
        ),
      );
}