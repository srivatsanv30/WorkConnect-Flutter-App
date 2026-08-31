import 'dart:async';
import 'package:flutter/material.dart';
import '../auth/user_model.dart';
import '../home/home_overview_screen.dart';
import '../hub/workspace_hub_screen.dart';
import '../jobs/post_job_screen.dart';
import '../collaboration/collaboration_workspace_screen.dart';
import '../profile/profile_screen.dart';
import '../notification/notification_service.dart';
import '../notification/notifications_screen.dart';

/// The app's main shell after login: bottom nav across the five
/// core screens, mirroring the web sidebar's Home / Workspace Hub /
/// Post a Job / Collaboration Workspace / My Profile structure.
class MainShell extends StatefulWidget {
  final AppUser? user;

  const MainShell({super.key, required this.user});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  String get _userName => widget.user?.name ?? 'there';

  void _goTo(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeOverviewScreen(userName: _userName, onNavigate: _goTo),
      WorkspaceHubScreen(userName: _userName, userId: widget.user?.id ?? '', onPostProject: () => _goTo(2)),
      PostJobScreen(onPosted: () => _goTo(1)),
      CollaborationWorkspaceScreen(currentUserId: widget.user?.id ?? ''),
      ProfileScreen(user: widget.user),
    ];

    final titles = [
      'WorkConnect',
      'Workspace Hub',
      'Post a Job',
      'Collaboration Workspace',
      'My Profile',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index], style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_index == 0 || _index == 1)
            _NotificationBell(currentUserId: widget.user?.id ?? ''),
        ],
      ),
      body: SafeArea(child: screens[_index]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _goTo,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), label: 'Hub'),
          BottomNavigationBarItem(icon: Icon(Icons.work_outline), label: 'Post Job'),
          BottomNavigationBarItem(icon: Icon(Icons.layers_outlined), label: 'Workspace'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class _NotificationBell extends StatefulWidget {
  final String currentUserId;
  const _NotificationBell({required this.currentUserId});

  @override
  State<_NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<_NotificationBell> {
  final _notificationService = NotificationService();
  int _unreadCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchCount();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchCount());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchCount() async {
    final list = await _notificationService.fetchNotifications();
    final count = list.where((n) => n['read'] != true).length;
    if (mounted) {
      setState(() => _unreadCount = count);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => NotificationsScreen(currentUserId: widget.currentUserId),
              ),
            ).then((_) => _fetchCount());
          },
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                '$_unreadCount',
                style: TextStyle(
                  color: Theme.of(context).cardColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}