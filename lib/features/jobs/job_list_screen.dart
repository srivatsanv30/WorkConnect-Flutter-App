import 'package:flutter/material.dart';

/// Job Posting Module entry point.
/// Will later pull from GET /api/jobs with skill-based filtering.
class JobListScreen extends StatelessWidget {
  const JobListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jobs & Tasks'),
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
