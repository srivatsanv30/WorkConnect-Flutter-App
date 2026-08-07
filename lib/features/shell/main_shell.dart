import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../auth/auth_service.dart';
import '../auth/auth_screen.dart';
import '../auth/user_model.dart';
import '../home/home_overview_screen.dart';
import '../hub/workspace_hub_screen.dart';
import '../jobs/post_job_screen.dart';
import '../collaboration/collaboration_workspace_screen.dart';
import '../profile/profile_screen.dart';

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

  Future<void> _logout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

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
      'Collaboration',
      'My Profile',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index], style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: _logout,
          ),
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