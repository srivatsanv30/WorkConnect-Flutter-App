import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  static const List<Map<String, String>> _faqs = [
    {
      'q': 'What is WorkConnect?',
      'a': 'WorkConnect is a hybrid workspace platform that bridges project management, '
          'remote mentorship, and real-time collaboration. It helps teams structure tasks, '
          'get AI-powered guidance, and build projects together.',
    },
    {
      'q': 'How do I post a job or project?',
      'a': 'Navigate to the "Post Job" tab from the bottom navigation bar. Fill in your '
          'project title, description, required skills, and budget. Once posted, it will '
          'appear in the Workspace Hub for others to discover.',
    },
    {
      'q': 'How does the AI Workflow Breakdown work?',
      'a': 'When you create a project, our AI analyzes your description and automatically '
          'generates milestones, required skills, and estimated duration targets. You can '
          'customize these suggestions to fit your needs.',
    },
    {
      'q': 'What is the Reputation & Completion Score?',
      'a': 'Every completed job and successful collaboration builds your trust score. '
          'This verified reputation is displayed on your public profile, helping you '
          'stand out and attract better opportunities.',
    },
    {
      'q': 'How does Live Visual Guidance Mode work?',
      'a': 'You can share your screen remotely with mentors or teammates. They can provide '
          'live guidance, annotate on-screen, and help resolve blockers in real time '
          'through the Collaboration Workspace.',
    },
    {
      'q': 'Is my data secure?',
      'a': 'Yes. We use industry-standard encryption for data at rest and in transit. '
          'Your personal information is never shared with third parties without consent. '
          'All authentication is handled securely via Firebase.',
    },
    {
      'q': 'How do I contact support?',
      'a': 'You can report any issues via the "Report a Bug" option in your Profile settings. '
          'Our team reviews all submissions and will respond via email within 24–48 hours.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQ'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.heroGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.help_outline, color: AppTheme.primary, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Frequently Asked Questions',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Find answers to common questions about WorkConnect.',
                          style: TextStyle(color: Colors.black45, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // FAQ items
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7FB),
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: List.generate(_faqs.length, (i) {
                  final faq = _faqs[i];
                  return Column(
                    children: [
                      ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        title: Text(
                          faq['q']!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        children: [
                          Text(
                            faq['a']!,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                      if (i < _faqs.length - 1)
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
