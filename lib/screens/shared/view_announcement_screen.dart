import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app_theme.dart';

class ViewAnnouncementScreen extends StatelessWidget {
  final Map<String, dynamic> announcement;

  const ViewAnnouncementScreen(
      {super.key, required this.announcement});

  @override
  Widget build(BuildContext context) {
    final dateTime = announcement['dateTime'] != null
        ? (announcement['dateTime'] as Timestamp).toDate()
        : null;
    final needsTech =
        announcement['needsTechAssist'] ?? false;
    final agendaItems = List<String>.from(
        announcement['agendaItems'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('View Announcement'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Title
            Text(
              announcement['title'] ?? '',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Tech Assist Badge
            if (needsTech)
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
                    Text(
                      'Tech Assistance Required',
                      style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Details Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    _buildRow('Authority',
                        announcement['authority'] ?? '—'),
                    _buildDivider(),

                    _buildRow('To Preside',
                        announcement['toPreside'] ?? '—'),
                    _buildDivider(),

                    _buildRow(
                      'Date & Time',
                      dateTime != null
                          ? '${dateTime.day}/${dateTime.month}/${dateTime.year}   ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}'
                          : '—',
                    ),
                    _buildDivider(),

                    _buildRow('Venue',
                        announcement['venueName'] ?? '—'),
                    _buildDivider(),

                    _buildRow('Attendee Type',
                        announcement['attendeeType'] ?? '—'),
                    _buildDivider(),

                    // Agenda
                    const Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: 12),
                      child: Text(
                        'Agenda',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    ...agendaItems.asMap().entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(
                                bottom: 8, left: 8),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.primaryBlue,
                                    borderRadius:
                                        BorderRadius.circular(
                                            12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${entry.key + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child:
                                      Text(entry.value),
                                ),
                              ],
                            ),
                          ),
                        ),

                    if ((announcement[
                                'invitedOrganizations'] ??
                            '')
                        .isNotEmpty) ...[
                      _buildDivider(),
                      _buildRow(
                          'Invited Organizations',
                          announcement[
                                  'invitedOrganizations'] ??
                              ''),
                    ],

                    if ((announcement['invitedNames'] ?? '')
                        .isNotEmpty) ...[
                      _buildDivider(),
                      _buildRow('Invited Names',
                          announcement['invitedNames'] ??
                              ''),
                    ],

                    if ((announcement['tasks'] ?? '')
                        .isNotEmpty) ...[
                      _buildDivider(),
                      _buildRow('Tasks',
                          announcement['tasks'] ?? ''),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() => const Divider(height: 1);
}