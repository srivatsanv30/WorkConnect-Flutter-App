import 'package:flutter/material.dart';

/// AI Task Breakdown: user enters a goal, this calls your Python/Gemini
/// backend endpoint and renders the returned subtasks.
class AiTaskBreakdownScreen extends StatelessWidget {
  const AiTaskBreakdownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Task Breakdown')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Describe your project and AI will break it into steps.'),
      ),
    );
  }
}
