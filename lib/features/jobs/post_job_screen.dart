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
  List<String> _milestones = [];

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
        _milestones = (data['milestones'] as List?)?.cast<String>() ?? [];
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
      milestones: _milestones.isNotEmpty ? _milestones : null,
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
            Text(
              'Create Collaborative Project',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'Define the deliverables, invite teammates, and run AI '
              'assistance to auto-breakdown milestones.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 13),
            ),
            SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology_alt_outlined, color: AppTheme.primary, size: 20),
                      SizedBox(width: 8),
                      Text('AI Task Breakdown Assistant',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Enter your idea (e.g. "Flutter chat app") and let AI '
                    'structure the deliverables.',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _aiIdeaController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Build an e-commerce website...',
                      isDense: true,
                    ),
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isBreakingDown ? null : _handleAiBreakdown,
                      child: _isBreakingDown
                          ? SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).cardColor,
                              ),
                            )
                          : const Text('Breakdown'),
                    ),
                  ),
                ],
              ),
            ),
            if (_milestones.isNotEmpty) ...[
              SizedBox(height: 16),
              Text('AI-Generated Milestones', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              ...List.generate(_milestones.length, (i) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: AppTheme.primary.withAlpha(25),
                    child: Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  ),
                  title: Text(_milestones[i], style: TextStyle(fontSize: 14)),
                  trailing: IconButton(
                    icon: Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _milestones.removeAt(i)),
                  ),
                ),
              )),
            ],
            SizedBox(height: 24),
            Text('Project Title', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 6),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'e.g. Build API integration backend'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            SizedBox(height: 16),
            Text('Detailed Description', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 6),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Describe the goals and collaboration requirements...',
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Description is required' : null,
            ),
            SizedBox(height: 16),
            Text('Required Skills (comma separated)', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 6),
            TextFormField(
              controller: _skillsController,
              decoration: const InputDecoration(hintText: 'e.g. React, Node.js, Express'),
            ),
            SizedBox(height: 16),
            Text('Priority level', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _priority,
              items: ['Low', 'Medium', 'High', 'Urgent']
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => _priority = v ?? 'Medium'),
            ),
            SizedBox(height: 16),
            Text('Target Deadline', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 6),
            InkWell(
              onTap: _pickDeadline,
              child: InputDecorator(
                decoration: const InputDecoration(),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45)),
                    SizedBox(width: 10),
                    Text(
                      _deadline == null
                          ? 'Select a date'
                          : '${_deadline!.day.toString().padLeft(2, '0')}-'
                            '${_deadline!.month.toString().padLeft(2, '0')}-'
                            '${_deadline!.year}',
                      style: TextStyle(
                        color: _deadline == null ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45) : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            if (_errorMessage != null) ...[
              Text(_errorMessage!, style: TextStyle(color: Colors.red)),
              SizedBox(height: 12),
            ],
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).cardColor),
                    )
                  : Text('Post Project'),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}