import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app_theme.dart';
import '../../services/announcement_service.dart';
import 'view_announcement_screen.dart';

// Filter options for Tech Admin news feed
enum _FeedFilter { all, tagged, techAssistance }

class NewsFeedScreen extends StatefulWidget {
  final bool isTechAdmin;
  const NewsFeedScreen({super.key, this.isTechAdmin = false});

  @override
  State<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen> {
  final _service = AnnouncementService();

  List<Map<String, dynamic>> _announcements = [];
  bool _isLoading = true;
  _FeedFilter _activeFilter = _FeedFilter.all;

  // Tech Admin's own UID — used to determine "tagged" announcements
  String? _currentUid;

  @override
  void initState() {
    super.initState();
    if (widget.isTechAdmin) {
      _currentUid = FirebaseAuth.instance.currentUser?.uid;
    }
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = widget.isTechAdmin
          ? await _service.getTechAdminFeed()
          : await _service.getNewsFeed();
      if (!mounted) return;
      setState(() => _announcements = data);
    } catch (e) {
      if (!mounted) return;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Returns the filtered list based on active chip
  List<Map<String, dynamic>> get _filteredAnnouncements {
    if (!widget.isTechAdmin || _activeFilter == _FeedFilter.all) {
      return _announcements;
    }

    return _announcements.where((a) {
      final visibleTo = List<String>.from(a['visibleTo'] ?? []);
      final needsTech = a['needsTechAssist'] == true;
      final isTagged =
          _currentUid != null && visibleTo.contains(_currentUid);

      if (_activeFilter == _FeedFilter.tagged) return isTagged;
      if (_activeFilter == _FeedFilter.techAssistance) return needsTech;
      return true;
    }).toList();
  }

  // Determines the category of an announcement for badge display
  _AnnouncementCategory _getCategory(Map<String, dynamic> a) {
    if (!widget.isTechAdmin) return _AnnouncementCategory.none;

    final visibleTo = List<String>.from(a['visibleTo'] ?? []);
    final needsTech = a['needsTechAssist'] == true;
    final isTagged =
        _currentUid != null && visibleTo.contains(_currentUid);

    if (isTagged && needsTech) return _AnnouncementCategory.both;
    if (isTagged) return _AnnouncementCategory.tagged;
    if (needsTech) return _AnnouncementCategory.techAssistance;
    return _AnnouncementCategory.none;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredAnnouncements;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── HEADER ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Summary',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.isTechAdmin
                          ? 'Announcements you are tagged in or need tech assistance'
                          : 'Announcements you are mentioned in',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _loadAnnouncements,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ],
            ),

            // ── FILTER CHIPS (Tech Admin only) ──
            if (widget.isTechAdmin) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  _filterChip(
                    label: 'All',
                    filter: _FeedFilter.all,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    label: 'Tagged',
                    filter: _FeedFilter.tagged,
                    color: Colors.blue,
                    icon: Icons.label,
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    label: 'Tech Assistance',
                    filter: _FeedFilter.techAssistance,
                    color: Colors.green,
                    icon: Icons.build_circle,
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // ── CONTENT ──
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) =>
                              _buildCard(filtered[index]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Filter Chip Widget ──
  Widget _filterChip({
    required String label,
    required _FeedFilter filter,
    required Color color,
    IconData? icon,
  }) {
    final isActive = _activeFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color : color.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 13, color: isActive ? Colors.white : color),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    if (widget.isTechAdmin) {
      switch (_activeFilter) {
        case _FeedFilter.tagged:
          message = 'No announcements where you are tagged';
          break;
        case _FeedFilter.techAssistance:
          message = 'No announcements needing tech assistance';
          break;
        default:
          message =
              'Announcements tagged to you or needing tech assistance will appear here';
      }
    } else {
      message = 'Announcements you are mentioned in will appear here';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.feed, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No announcements yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> announcement) {
    final needsTech = announcement['needsTechAssist'] ?? false;
    final dateTime = announcement['dateTime'] != null
        ? (announcement['dateTime'] as Timestamp).toDate()
        : null;
    final attendeeType = announcement['attendeeType'] ?? 'Physical';
    final category = _getCategory(announcement);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── TITLE ROW + BADGES ──
            Row(
              children: [
                Expanded(
                  child: Text(
                    announcement['title'] ?? 'No Title',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Attendee type badge
                _buildBadge(
                  label: attendeeType,
                  icon: attendeeType == 'Virtual'
                      ? Icons.video_call
                      : Icons.person,
                  color: attendeeType == 'Virtual'
                      ? Colors.purple
                      : Colors.blue,
                ),

                // ── Tech Admin category badges ──
                if (widget.isTechAdmin) ...[
                  if (category == _AnnouncementCategory.tagged ||
                      category == _AnnouncementCategory.both) ...[
                    const SizedBox(width: 6),
                    _buildBadge(
                      label: 'Tagged',
                      icon: Icons.label,
                      color: Colors.blue,
                    ),
                  ],
                  if (category == _AnnouncementCategory.techAssistance ||
                      category == _AnnouncementCategory.both) ...[
                    const SizedBox(width: 6),
                    _buildBadge(
                      label: 'Tech Assist',
                      icon: Icons.build_circle,
                      color: Colors.green,
                    ),
                  ],
                ] else ...[
                  // Non-Tech Admin: keep original orange tech assist badge
                  if (needsTech) ...[
                    const SizedBox(width: 6),
                    _buildBadge(
                      label: 'Tech Assist',
                      icon: Icons.build_circle,
                      color: Colors.orange,
                    ),
                  ],
                ],
              ],
            ),
            const SizedBox(height: 12),

            // ── INFO CHIPS ──
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (dateTime != null)
                  _buildInfoChip(
                    Icons.calendar_today,
                    '${dateTime.day}/${dateTime.month}/${dateTime.year}  ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}',
                  ),
                _buildInfoChip(
                  Icons.location_on,
                  announcement['venueName'] ?? 'No venue',
                ),
                _buildInfoChip(
                  Icons.people,
                  '${(announcement['attendeeUnitIds'] as List?)?.length ?? 0} unit(s)',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── VIEW BUTTON ──
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => ViewAnnouncementScreen.show(
                    context, announcement),
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('View'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryBlue,
                  side: const BorderSide(color: AppTheme.primaryBlue),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }
}

// Internal enum to categorize announcements for Tech Admin
enum _AnnouncementCategory { none, tagged, techAssistance, both }