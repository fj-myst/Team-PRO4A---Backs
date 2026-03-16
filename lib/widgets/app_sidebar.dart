import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/auth_service.dart';
import '../screens/auth/login_screen.dart';

class NavItem {
  final IconData icon;
  final String label;
  final List<NavItem>? children; // <-- for dropdown groups
  const NavItem({required this.icon, required this.label, this.children});
}

class AppSidebar extends StatefulWidget {
  final List<NavItem> navItems;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeToggle;
  final String roleLabel;
  final Color roleColor;
  final IconData roleIcon;

  const AppSidebar({
    super.key,
    required this.navItems,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.isDarkMode,
    required this.onDarkModeToggle,
    required this.roleLabel,
    required this.roleColor,
    required this.roleIcon,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {

  @override
  Widget build(BuildContext context) {
    // Flatten nav items to map selectedIndex correctly
    int flatIndex = 0;
    final List<Widget> navWidgets = [];

    for (final item in widget.navItems) {
      if (item.children != null) {
        // Group with dropdown
        final groupChildren = <Widget>[];
        for (final child in item.children!) {
          final currentIndex = flatIndex;
          final isSelected = widget.selectedIndex == currentIndex;
          groupChildren.add(_menuItem(
            icon: child.icon,
            title: child.label,
            index: currentIndex,
            indent: true,
          ));
          flatIndex++;
        }
        navWidgets.add(
          Theme(
            data: ThemeData().copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: Icon(item.icon, color: Colors.white70, size: 20),
              title: Text(
                item.label,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              iconColor: Colors.white70,
              collapsedIconColor: Colors.white70,
              childrenPadding: const EdgeInsets.only(left: 16),
              children: groupChildren,
            ),
          ),
        );
      } else {
        // Regular item
        final currentIndex = flatIndex;
        navWidgets.add(_menuItem(
          icon: item.icon,
          title: item.label,
          index: currentIndex,
        ));
        flatIndex++;
      }
    }

    return Container(
      width: 260,
      color: const Color(0xFF0F2744),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Logo
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'TEAM-PRO4A',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Role Badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: widget.roleColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.roleIcon, size: 13, color: widget.roleColor),
                    const SizedBox(width: 6),
                    Text(
                      widget.roleLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.roleColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Divider(color: Colors.white24),

            // Nav Items
            Expanded(
              child: ListView(children: navWidgets),
            ),

            const Divider(color: Colors.white24),

            // Dark Mode Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    widget.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    size: 18,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.isDarkMode ? 'Dark Mode' : 'Light Mode',
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const Spacer(),
                  Switch(
                    value: widget.isDarkMode,
                    onChanged: widget.onDarkModeToggle,
                    activeColor: AppTheme.primaryBlue,
                  ),
                ],
              ),
            ),

            // Logout
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
              onTap: _logout,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required int index,
    bool indent = false,
  }) {
    final isSelected = widget.selectedIndex == index;
    return Container(
      margin: EdgeInsets.only(left: indent ? 8 : 4, right: 4, top: 2, bottom: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white70,
          size: indent ? 18 : 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: indent ? 13 : 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () => widget.onItemSelected(index),
      ),
    );
  }

  void _logout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }
}