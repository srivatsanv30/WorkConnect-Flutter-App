import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import 'job_service.dart';

class PostJobScreen extends StatefulWidget {
  final VoidCallback onPosted;

  const PostJobScreen({super.key, required this.onPosted});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _skillsController = TextEditingController();
  final _aiIdeaController = TextEditingController();

  String _priority = 'Medium';
  DateTime? _deadline;
  bool _isLoading = false;
  bool _isBreakingDown = false;
  String? _errorMessage;

  final _jobService = JobService();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _skillsController.dispose();
    _aiIdeaController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 14)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _handleAiBreakdown() async {
    final idea = _aiIdeaController.text.trim();
    if (idea.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Type an idea first, e.g. "Build a chat app"')),
      );
      return;
    }

    setState(() => _isBreakingDown = true);

    final result = await _jobService.aiBreakdown(idea);

    if (!mounted) return;
    setState(() => _isBreakingDown = false);

    if (result.success && result.job != null) {
      final data = result.job!;
      setState(() {
        _titleController.text = data['title'] ?? '';
        _descriptionController.text = data['description'] ?? '';
        final skills = (data['skillsRequired'] as List?)?.cast<String>() ?? [];
        _skillsController.text = skills.join(', ');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI filled in the form below — review and adjust as needed!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'AI breakdown failed')),
      );
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_deadline == null) {
      setState(() => _errorMessage = 'Please pick a target deadline');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final skills = _skillsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final result = await _jobService.createJob(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      skillsRequired: skills,
      priority: _priority,
      deadline: _deadline!.toIso8601String(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project posted successfully!')),
      );
      widget.onPosted();
    } else {
      setState(() => _errorMessage = result.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Create Collaborative Project',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Define the deliverables, invite teammates, and run AI '
              'assistance to auto-breakdown milestones.',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F1FD),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDDD6F9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.psychology_alt_outlined, color: AppTheme.primary, size: 20),
                      SizedBox(width: 8),
                      Text('AI Task Breakdown Assistant',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Enter your idea (e.g. "Flutter chat app") and let AI '
                    'structure the deliverables.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _aiIdeaController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Build an e-commerce website...',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isBreakingDown ? null : _handleAiBreakdown,
                      icon: _isBreakingDown
                          ? const SizedBox(
                              height: 14,
                              width: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.auto_fix_high, size: 16),
                      label: Text(_isBreakingDown ? 'Thinking...' : 'Breakdown'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Project Title', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'e.g. Build API integration backend'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            const Text('Detailed Description', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Describe the goals and collaboration requirements...',
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Description is required' : null,
            ),
            const SizedBox(height: 16),
            const Text('Required Skills (comma separated)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _skillsController,
              decoration: const InputDecoration(hintText: 'e.g. React, Node.js, Express'),
            ),
            const SizedBox(height: 16),
            const Text('Priority level', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _priority,
              items: const ['Low', 'Medium', 'High', 'Urgent']
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => _priority = v ?? 'Medium'),
            ),
            const SizedBox(height: 16),
            const Text('Target Deadline', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickDeadline,
              child: InputDecorator(
                decoration: const InputDecoration(),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.black45),
                    const SizedBox(width: 10),
                    Text(
                      _deadline == null
                          ? 'Select a date'
                          : '${_deadline!.day.toString().padLeft(2, '0')}-'
                            '${_deadline!.month.toString().padLeft(2, '0')}-'
                            '${_deadline!.year}',
                      style: TextStyle(
                        color: _deadline == null ? Colors.black45 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null) ...[
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
            ],
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Post Project'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}