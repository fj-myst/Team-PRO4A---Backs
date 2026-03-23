import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../app_theme.dart';
import '../../services/announcement_service.dart';
import '../shared/view_announcement_screen.dart';
import 'personnel_calendar_screen.dart';
import '../auth/login_screen.dart';

class PersonnelNewsFeedScreen extends StatefulWidget {
  const PersonnelNewsFeedScreen({super.key});

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

  late Timer _clockTimer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _clockTimer =
        Timer.periodic(const Duration(seconds: 1), (_) {
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

      // Load user profile + announcements in parallel
      final results = await Future.wait([
        _firestore.collection('users').doc(uid).get(),
        _service.getPersonnelFeed(),
      ]);

      final userDoc = results[0] as DocumentSnapshot;
      final announcements =
          results[1] as List<Map<String, dynamic>>;

      if (!mounted) return;
      setState(() {
        _userData = userDoc.data() as Map<String, dynamic>?;
        _announcements = announcements;
      });
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
        // ── Navigate back to LoginScreen, clearing the entire stack ──
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false, // removes all previous routes
        );
      }
    }

  String get _clockString {
    final h = _now.hour.toString().padLeft(2, '0');
    final m = _now.minute.toString().padLeft(2, '0');
    return '$h:$m PHT (UTC+8)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Column(
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
    );
  }

  // ── HEADER ──
  Widget _buildHeader() {
    final name = (_userData?['name'] ?? 'Personnel')
      .toString()
      .toUpperCase();
    final position = _userData?['position'] ?? '';
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A1A3A), // dark navy base
        image: DecorationImage(
          image: AssetImage('assets/images/calabrz.png'),
          fit: BoxFit.cover,
          alignment: Alignment.centerRight,
          opacity: 0.15, // subtle — just enough to see the map
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            children: [

              // Top row — logout
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: _confirmLogout,           // ← new dialog logout
                    icon: const Icon(Icons.logout,
                        color: Colors.white70, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Profile row — seal + name + unit
              Row(
                children: [

                  // PNP Seal placeholder (replace with Image.asset if you have the logo)
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white24, width: 2),
                      color: Colors.white10,
                    ),
                    child: ClipOval(
                      child: _userData?['sealUrl'] != null
                          ? Image.network(
                              _userData!['sealUrl'],
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.shield,
                              color: Colors.white54, size: 30),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Name + unit
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (position.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            position,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                              height: 1.4,
                            ),
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

  // ── BODY ─────────────────────────────────────────────────────
  Widget _buildBody() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [

        // NEWS FEED heading + bell
        SliverToBoxAdapter(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                  ],
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.notifications_none,
                        color: Color(0xFF0A1A3A),
                        size: 28,
                      ),
                    ),
                    if (_announcements.isNotEmpty)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${_announcements.length}',
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

  // ── ANNOUNCEMENT CARD ────────────────────────────────────────
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
      onTap: () =>
          ViewAnnouncementScreen.show(context, announcement),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D2145),
              Color(0xFF1A3A6A),
            ],
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

              // Title — centered
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

              // Info rows — left aligned
              _cardRow('VENUE:',
                  announcement['venueName'] ?? 'TBA'),
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
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  // ── BOTTOM BAR ───────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: 24, vertical: 10),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            // Live clock
            Text(
              _clockString,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0A1A3A),
                letterSpacing: 0.3,
              ),
            ),

            // Calendar button
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const PersonnelCalendarScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1A3A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_month,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── EMPTY STATE ──────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.feed,
              size: 64, color: Colors.grey.shade300),
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

  // ── HELPERS ──────────────────────────────────────────────────
  String _weekday(int w) => const [
        '', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
      ][w];

  String _monthName(int m) => const [
        '', 'January', 'February', 'March', 'April', 'May',
        'June', 'July', 'August', 'September', 'October',
        'November', 'December'
      ][m];
}