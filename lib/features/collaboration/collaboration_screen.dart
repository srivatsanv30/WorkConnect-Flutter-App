import 'package:flutter/material.dart';

/// Collaboration Workspace: team chat, file sharing, meeting links.
/// Wire up Socket.IO client here once backend is ready.
class CollaborationScreen extends StatelessWidget {
  final String jobId;
  const CollaborationScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workspace')),
      body: Center(child: Text('Workspace for job $jobId')),
    );
  }
}
