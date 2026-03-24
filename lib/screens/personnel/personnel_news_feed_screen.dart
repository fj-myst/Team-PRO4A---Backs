import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../services/announcement_service.dart';
import '../shared/view_announcement_screen.dart';
import '../auth/login_screen.dart';

class PersonnelNewsFeedScreen extends StatefulWidget {
  final Set<String> viewedIds;
  final bool notificationsSeen;
  final ValueChanged<Set<String>> onViewedIdsChanged;
  final ValueChanged<bool> onNotificationsSeenChanged;

  const PersonnelNewsFeedScreen({
    super.key,
    required this.viewedIds,
    required this.notificationsSeen,
    required this.onViewedIdsChanged,
    required this.onNotificationsSeenChanged,
  });

  @override
  State<PersonnelNewsFeedScreen> createState() =>
      _PersonnelNewsFeedScreenState();
}

class _PersonnelNewsFeedScreenState
    extends State<PersonnelNewsFeedScreen> {
  final _service = AnnouncementService();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _announcements = [];
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _showNotifications = false;

  final GlobalKey _bellKey = GlobalKey();

  late Timer _clockTimer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _loadData();
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      // Step 1: Get user document
      final userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      final unitId = userData?['unitId'] ?? '';

      // Step 2: Get unit name
      String unitName = '';
      if (unitId.isNotEmpty) {
        final unitDoc = await _firestore
            .collection('units')
            .doc(unitId)
            .get();
        unitName = unitDoc.data()?['name'] ?? '';
      }

      // Step 3: Merge unitName
      final enrichedUserData = {
        ...?userData,
        'unitName': unitName,
      };

      // Step 4: Load announcements
      final announcements = await _service.getPersonnelFeed();

      if (!mounted) return;
      setState(() {
        _userData = enrichedUserData;
        _announcements = announcements;
      });

      // Reset notification state on fresh load
      widget.onNotificationsSeenChanged(false);
      widget.onViewedIdsChanged({});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF0A1A3A), width: 2),
        ),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'CONFIRM LOGOUT',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0A1A3A),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A1A3A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'YES',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 100,
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A6080),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'NO',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _toggleNotifications() {
    final unviewed = _announcements
        .where((a) => !widget.viewedIds.contains(a['id']))
        .toList();

    setState(() {
      _showNotifications = !_showNotifications;
      if (_showNotifications) {
        widget.onNotificationsSeenChanged(true);
        if (unviewed.isEmpty) _showNotifications = false;
      }
    });
  }

  String _formatDate(dynamic dateTime) {
    if (dateTime == null) return 'TBA';
    final dt = (dateTime as Timestamp).toDate();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: _buildBody(),
                      ),
              ),
            ],
          ),

          // Tap outside to close
          if (_showNotifications)
            Positioned.fill(
              child: GestureDetector(
                onTap: () =>
                    setState(() => _showNotifications = false),
                behavior: HitTestBehavior.translucent,
                child: Container(color: Colors.transparent),
              ),
            ),

          // Notification dropdown
          if (_showNotifications)
            Positioned(
              top: _getNotificationPanelTop(),
              right: 12,
              child: _buildNotificationPanel(),
            ),
        ],
      ),
    );
  }

  double _getNotificationPanelTop() {
    final RenderBox? box =
        _bellKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return 120;
    final position = box.localToGlobal(Offset.zero);
    return position.dy + box.size.height + 4;
  }

  // ── NOTIFICATION PANEL ──
  Widget _buildNotificationPanel() {
    final unviewed = _announcements
        .where((a) => !widget.viewedIds.contains(a['id']))
        .take(5)
        .toList();

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      child: Container(
        width: 300,
        constraints: const BoxConstraints(maxHeight: 360),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // Panel header
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF0A1A3A),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'NOTIFICATIONS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _showNotifications = false),
                    child: const Icon(Icons.close,
                        color: Colors.white60, size: 16),
                  ),
                ],
              ),
            ),

            // Items
            if (unviewed.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No new announcements',
                  style:
                      TextStyle(color: Colors.grey, fontSize: 13),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: unviewed.length,
                  separatorBuilder: (_, __) => Divider(
                      height: 1, color: Colors.grey.shade100),
                  itemBuilder: (context, index) {
                    final a = unviewed[index];
                    return InkWell(
                      onTap: () {
                        final id = a['id'] as String?;
                        if (id != null) {
                          final updated =
                              Set<String>.from(widget.viewedIds)
                                ..add(id);
                          widget.onViewedIdsChanged(updated);
                        }
                        setState(() => _showNotifications = false);
                        ViewAnnouncementScreen.show(context, a);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A1A3A)
                                    .withOpacity(0.08),
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.campaign,
                                color: Color(0xFF0A1A3A),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a['title'] ?? 'Untitled',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0A1A3A),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _formatDate(a['dateTime']),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: Colors.grey, size: 16),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── HEADER ──
  Widget _buildHeader() {
    final name =
        (_userData?['name'] ?? '').toString().toUpperCase();
    final unitName = _userData?['unitName'] ?? '';
    final position = _userData?['position'] ?? '';
    final subtitle =
        [unitName, position].where((s) => s.isNotEmpty).join(' - ');

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A1A3A),
        image: DecorationImage(
          image: AssetImage('assets/images/calabrz.png'),
          fit: BoxFit.cover,
          alignment: Alignment.centerRight,
          opacity: 0.15,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TEAM-PRO4A',
                    style: TextStyle(
                      color: Color.fromARGB(200, 255, 255, 255),
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  IconButton(
                    onPressed: _confirmLogout,
                    icon: const Icon(Icons.logout,
                        color: Colors.white70, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Image.asset('assets/images/PNP-logo.png',
                      width: 52, height: 52),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── BODY ──
  Widget _buildBody() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [

        // NEWS FEED heading + bell
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'NEWS FEED',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0A1A3A),
                    letterSpacing: 1.2,
                  ),
                ),

                // Bell with badge
                GestureDetector(
                  key: _bellKey,
                  onTap: _toggleNotifications,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.notifications_none,
                          color: Color(0xFF0A1A3A),
                          size: 28,
                        ),
                      ),
                      if (_announcements
                              .where((a) => !widget.viewedIds
                                  .contains(a['id']))
                              .isNotEmpty &&
                          !widget.notificationsSeen)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${_announcements.where((a) => !widget.viewedIds.contains(a['id'])).length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Cards or empty state
        if (_announcements.isEmpty)
          SliverFillRemaining(child: _buildEmptyState())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildCard(_announcements[index]),
                childCount: _announcements.length,
              ),
            ),
          ),
      ],
    );
  }

  // ── ANNOUNCEMENT CARD ──
  Widget _buildCard(Map<String, dynamic> announcement) {
    final dateTime = announcement['dateTime'] != null
        ? (announcement['dateTime'] as Timestamp).toDate()
        : null;

    final dateStr = dateTime != null
        ? '${_weekday(dateTime.weekday)}, '
            '${_monthName(dateTime.month)} ${dateTime.day}, '
            '${dateTime.year}  '
            '${dateTime.hour.toString().padLeft(2, '0')}:'
            '${dateTime.minute.toString().padLeft(2, '0')}'
        : 'TBA';

    return GestureDetector(
      onTap: () {
        final id = announcement['id'] as String?;
        if (id != null) {
          final updated = Set<String>.from(widget.viewedIds)
            ..add(id);
          widget.onViewedIdsChanged(updated);
        }
        ViewAnnouncementScreen.show(context, announcement);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D2145), Color(0xFF1A3A6A)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A1A3A).withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                (announcement['title'] ?? 'UNTITLED')
                    .toString()
                    .toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 14),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 12),
              _cardRow(
                  'VENUE:', announcement['venueName'] ?? 'TBA'),
              const SizedBox(height: 8),
              _cardRow('DATE AND TIME:', dateStr),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                color: Colors.white, fontSize: 12),
          ),
        ),
      ],
    );
  }

  // ── EMPTY STATE ──
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.feed, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No announcements yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Announcements you are mentioned in\nwill appear here',
            style: TextStyle(color: Colors.grey, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── HELPERS ──
  String _weekday(int w) => const [
        '', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
      ][w];

  String _monthName(int m) => const [
        '', 'January', 'February', 'March', 'April', 'May',
        'June', 'July', 'August', 'September', 'October',
        'November', 'December'
      ][m];
}