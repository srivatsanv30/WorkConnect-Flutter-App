import 'package:flutter/material.dart';
import 'post_job_screen.dart';

/// Job Posting Module entry point.
/// Will later pull from GET /api/jobs with skill-based filtering.
class JobListScreen extends StatelessWidget {
  const JobListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Jobs & Tasks'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PostJobScreen(
                onPosted: () => Navigator.pop(context),
              ),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
      body: Center(
        child: Text(
          'You are logged in!\nNo jobs yet — post one to get started.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
        ),
      ),
    );
  }
}
