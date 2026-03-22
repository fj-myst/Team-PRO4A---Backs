import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../widgets/app_sidebar.dart';
import '../../widgets/notification_bell.dart';
import '../shared/create_announcement_screen.dart';
import '../shared/recents_screen.dart';
import '../shared/news_feed_screen.dart';
import 'manage_units_screen.dart';
import 'venue_management_screen.dart';
import 'manage_viewer_admins_screen.dart';
import 'tech_assistance_requests_screen.dart';
import '../shared/calendar_screen.dart';
import 'bug_reports_management_screen.dart';

class TechAdminHome extends StatefulWidget {
  const TechAdminHome({super.key});

  @override
  State<TechAdminHome> createState() => _TechAdminHomeState();
}

class _TechAdminHomeState extends State<TechAdminHome> {
  int _selectedIndex = 0;
  bool _isDarkMode = false;

  final List<NavItem> _navItems = [
    const NavItem(icon: Icons.dashboard, label: 'Dashboard'),
    const NavItem(icon: Icons.feed, label: 'News Feed'),
    const NavItem(icon: Icons.calendar_month, label: 'Calendar'),
    NavItem(
      icon: Icons.history,
      label: 'Activities',
      children: [
        const NavItem(icon: Icons.dynamic_feed, label: 'Recents'),
        const NavItem(icon: Icons.campaign, label: 'Create Announcements'),
      ],
    ),
    NavItem(
      icon: Icons.admin_panel_settings,
      label: 'Management',
      children: [
        const NavItem(icon: Icons.business, label: 'Manage Units'),
        const NavItem(icon: Icons.supervised_user_circle, label: 'Manage Viewer Admins'),
        const NavItem(icon: Icons.pin_drop, label: 'Venue Management'),
      ],
    ),
    const NavItem(icon: Icons.build_circle, label: 'Tech Assistance Requests'),
    const NavItem(icon: Icons.bug_report, label: 'Bug Reports'),
  ];

  final List<Widget> _pages = [
    const _PlaceholderPage(title: 'Dashboard'),                  // 0
    const NewsFeedScreen(isTechAdmin: true),                     // 1
    const CalendarScreen(calendarType: CalendarType.techAdmin),  // 2
    const RecentsScreen(),                                       // 3
    const CreateAnnouncementScreen(),                            // 4
    const ManageUnitsScreen(),                                   // 5
    const ManageViewerAdminsScreen(),                            // 6
    const VenueManagementScreen(),                               // 7
    const TechAssistanceRequestsScreen(),                        // 8
    const BugReportsManagementScreen(),                          // 9
  ];

  String get _currentPageTitle {
    const titles = [
      'Dashboard',
      'News Feed',
      'Calendar',
      'Recents',
      'Create Announcement',
      'Manage Units',
      'Manage Viewer Admins',
      'Venue Management',
      'Tech Assistance Requests',
      'Bug Reports',
    ];
    if (_selectedIndex < titles.length) return titles[_selectedIndex];
    return 'TEAM-PRO4A';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        body: Row(
          children: [
            AppSidebar(
              navItems: _navItems,
              selectedIndex: _selectedIndex,
              onItemSelected: (index) =>
                  setState(() => _selectedIndex = index),
              isDarkMode: _isDarkMode,
              onDarkModeToggle: (val) =>
                  setState(() => _isDarkMode = val),
              roleLabel: 'Tech Admin',
              roleColor: AppTheme.primaryBlue,
              roleIcon: Icons.shield,
            ),
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(context),
                  Expanded(child: _pages[_selectedIndex]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(
            _currentPageTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          const NotificationBell(),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.construction, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Coming soon...',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}