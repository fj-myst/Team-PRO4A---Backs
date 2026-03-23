import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'personnel_news_feed_screen.dart';
import 'personnel_calendar_screen.dart';
import 'personnel_bug_report_screen.dart';

class PersonnelHome extends StatefulWidget {
  const PersonnelHome({super.key});

  @override
  State<PersonnelHome> createState() => _PersonnelHomeState();
}

class _PersonnelHomeState extends State<PersonnelHome> {
  int _selectedIndex = 1;

  late Timer _clockTimer;
  late DateTime _now;

  final List<Widget> _screens = const [
    PersonnelCalendarScreen(),
    PersonnelNewsFeedScreen(),
    PersonnelBugReportScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  String get _timeString {
    final h = _now.hour.toString().padLeft(2, '0');
    final m = _now.minute.toString().padLeft(2, '0');
    final s = _now.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String get _dateString {
    const days = [
      'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'
    ];
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    final day = days[_now.weekday - 1];
    final month = months[_now.month - 1];
    final date = _now.day.toString().padLeft(2, '0');
    final year = _now.year;
    return '$day, $date $month $year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A1A3A),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [

              // ── NAV ICONS (left side) ──
              _navItem(index: 0, icon: Icons.calendar_month_outlined),
              _navItem(index: 1, icon: Icons.home_outlined),
              _navItem(index: 2, icon: Icons.bug_report_outlined),

              // ── DIVIDER ──
              Container(
                width: 1,
                height: 36,
                color: Colors.white12,
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),

              // ── DATE & TIME (right side) ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _timeString,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          fontFeatures: [
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _dateString,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({required int index, required IconData icon}) {
    final isActive = _selectedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : Colors.white38,
              size: 26,
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? 6 : 0,
              height: isActive ? 6 : 0,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}