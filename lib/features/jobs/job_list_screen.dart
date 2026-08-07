import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import '../auth/auth_screen.dart';

/// Job Posting Module entry point.
/// Will later pull from GET /api/jobs with skill-based filtering.
class JobListScreen extends StatelessWidget {
  const JobListScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthService().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jobs & Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: navigate to create-job screen
        },
        child: const Icon(Icons.add),
      ),
      body: const Center(
        child: Text(
          'You are logged in!\nNo jobs yet — post one to get started.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
      ),
    );
  }
}
