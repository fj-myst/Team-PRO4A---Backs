import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../shared/create_announcement_screen.dart';
import '../shared/recents_screen.dart';
import '../shared/news_feed_screen.dart';

class TechAdminHome extends StatefulWidget {
  const TechAdminHome({super.key});

  @override
  State<TechAdminHome> createState() => _TechAdminHomeState();
}

class _TechAdminHomeState extends State<TechAdminHome> {
  int _selectedIndex = 0;
  bool _isDarkMode = false;

  final List<_NavItem> _navItems = [
    _NavItem(icon: Icons.dashboard, label: 'Dashboard'),
    _NavItem(icon: Icons.feed, label: 'News Feed'),
    _NavItem(icon: Icons.dynamic_feed, label: 'Recents'),
    _NavItem(icon: Icons.campaign, label: 'Create Announcements'),
    _NavItem(icon: Icons.calendar_month, label: 'Calendar'),
    _NavItem(icon: Icons.business, label: 'Manage Units'),
    _NavItem(icon: Icons.admin_panel_settings, label: 'Manage Viewer Admins'),
    _NavItem(icon: Icons.build_circle, label: 'Tech Assistance Requests'),
    _NavItem(icon: Icons.bug_report, label: 'Bug Reports'),

  ];

  final List<Widget> _pages = [
    const _PlaceholderPage(title: 'Dashboard'),
    const NewsFeedScreen(),
    const RecentsScreen(),
    const CreateAnnouncementScreen(),    
    const _PlaceholderPage(title: 'Calendar'),
    const _PlaceholderPage(title: 'Manage Units'),
    const _PlaceholderPage(title: 'Manage Viewer Admins'),
    const _PlaceholderPage(title: 'Tech Assistance Requests'),
    const _PlaceholderPage(title: 'Bug Reports'),
  ];

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
            // Sidebar
            _buildSidebar(),
           
            // Main Content
            Expanded(
              child: _pages[_selectedIndex],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    final isDark = _isDarkMode;
    return Container(
      width: 250,
      color: isDark
          ? AppTheme.sidebarDark
          : AppTheme.sidebarLight,
      child: Column(
        children: [
          // App Logo & Title
          Container(
            padding: const EdgeInsets.symmetric(
                vertical: 5, horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.campaign,
                  color: AppTheme.primaryBlue,
                  size: 32,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Team-PRO4',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 1),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield,
                    size: 14, color: AppTheme.primaryBlue),
                SizedBox(width: 6),
                Text(
                  'Tech Admin',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

      const Divider(),

          // Nav Items
          Expanded(
            child: ListView.builder(
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = _selectedIndex == index;
                return Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryBlue
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: Icon(
                      item.icon,
                      color: isSelected
                          ? Colors.white
                          : isDark
                              ? Colors.white70
                              : Colors.black54,
                      size: 20,
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected
                            ? Colors.white
                            : isDark
                                ? Colors.white70
                                : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          const Divider(),

          // Dark Mode Toggle
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  _isDarkMode
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  size: 18,
                  color: isDark
                      ? Colors.white70
                      : Colors.black54,
                ),
                const SizedBox(width: 8),
                Text(
                  _isDarkMode ? 'Dark Mode' : 'Light Mode',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? Colors.white70
                        : Colors.black54,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _isDarkMode,
                  onChanged: (val) {
                    setState(() {
                      _isDarkMode = val;
                    });
                  },
                  activeColor: AppTheme.primaryBlue,
                ),
              ],
            ),
          ),

          // Logout Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, size: 16),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    await AuthService().logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }
}

// Placeholder page while we build real pages
class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.construction,
              size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Coming soon...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  _NavItem({required this.icon, required this.label});
}
