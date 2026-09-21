import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../jobs/job_service.dart';

/// AI Task Breakdown: user enters a goal, this calls your backend endpoint 
/// and renders the returned subtasks and skills.
class AiTaskBreakdownScreen extends StatefulWidget {
  const AiTaskBreakdownScreen({super.key});

  @override
  State<AiTaskBreakdownScreen> createState() => _AiTaskBreakdownScreenState();
}

class _AiTaskBreakdownScreenState extends State<AiTaskBreakdownScreen> {
  final _ideaController = TextEditingController();
  final _jobService = JobService();
  
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  String? _error;

  Future<void> _generateBreakdown() async {
    final idea = _ideaController.text.trim();
    if (idea.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    final res = await _jobService.aiBreakdown(idea);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res.success && res.job != null) {
          _result = res.job;
        } else {
          _error = res.errorMessage ?? 'Failed to generate breakdown';
        }
      });
    }
  }

  @override
  void dispose() {
    _ideaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Task Breakdown'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Describe your project and AI will break it into steps.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _ideaController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'e.g., Build a flutter task manager app with firebase...',
                      filled: true,
                      fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _generateBreakdown,
                    icon: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.auto_awesome),
                    label: Text(_isLoading ? 'Generating...' : 'Break it Down'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
              
            if (_result != null)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _result!['title'] ?? 'Generated Project',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _result!['description'] ?? '',
                          style: const TextStyle(fontSize: 15, height: 1.4),
                        ),
                        const SizedBox(height: 24),
                        const Text('Recommended Skills', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ((_result!['skillsRequired'] as List?) ?? []).map((skill) {
                            return Chip(
                              label: Text(skill.toString(), style: TextStyle(fontSize: 12, color: isDark ? Colors.white : AppTheme.primary)),
                              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                              side: BorderSide.none,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        const Text('Milestones', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ...((_result!['milestones'] as List?) ?? []).asMap().entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: AppTheme.primary,
                                  child: Text('${entry.key + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(entry.value.toString(), style: const TextStyle(fontSize: 15, height: 1.4)),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
