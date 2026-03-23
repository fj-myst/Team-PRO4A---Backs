// widgets/app_top_bar.dart
import 'package:flutter/material.dart';
import 'notification_bell.dart';

class AppTopBar extends StatelessWidget {
  final VoidCallback onToggleSidebar;
  final bool isSidebarVisible;

  const AppTopBar({
    super.key,
    required this.onToggleSidebar,
    required this.isSidebarVisible,
  });

  @override
  Widget build(BuildContext context) {
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
          IconButton(
            onPressed: onToggleSidebar,
            icon: Icon(isSidebarVisible ? Icons.menu_open : Icons.menu),
          ),
          const Spacer(),
          const NotificationBell(),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}