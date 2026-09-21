import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../auth/auth_service.dart';
import 'tracking_service.dart';

class ProgressTrackerScreen extends StatefulWidget {
  final Map<String, dynamic> job;
  final bool? isCreator;

  const ProgressTrackerScreen({super.key, required this.job, this.isCreator});

  @override
  State<ProgressTrackerScreen> createState() => _ProgressTrackerScreenState();
}

class _ProgressTrackerScreenState extends State<ProgressTrackerScreen> {
  static const _statuses = ['Pending', 'Accepted', 'In Progress', 'Review', 'Completed'];

  late Map<String, dynamic> _job;
  final _trackingService = TrackingService();
  final _milestoneController = TextEditingController();
  bool _isBusy = false;
  bool _isCreator = false;

  @override
  void initState() {
    super.initState();
    _job = widget.job;
    _initCreatorStatus();
  }

  Future<void> _initCreatorStatus() async {
    if (widget.isCreator != null) {
      setState(() => _isCreator = widget.isCreator!);
      return;
    }
    final uid = await AuthService().getCurrentUserId();
    final creatorId = (_job['creator'] is Map)
        ? _job['creator']['_id']?.toString()
        : _job['creator']?.toString();
    if (mounted) {
      setState(() {
        _isCreator = uid != null && uid == creatorId;
      });
    }
  }

  @override
  void dispose() {
    _milestoneController.dispose();
    super.dispose();
  }

  List<dynamic> get _milestones => (_job['milestones'] as List?) ?? [];

  double get _progress {
    if (_milestones.isEmpty) return 0;
    final done = _milestones.where((m) => m['done'] == true).length;
    return done / _milestones.length;
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _isBusy = true);
    final result = await _trackingService.updateStatus(_job['_id'], status);
    if (!mounted) return;
    setState(() => _isBusy = false);
    if (result.success && result.job != null) {
      setState(() => _job = result.job!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Failed')),
      );
    }
  }

  Future<void> _addMilestone() async {
    final title = _milestoneController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isBusy = true);
    final result = await _trackingService.addMilestone(_job['_id'], title);
    if (!mounted) return;
    setState(() => _isBusy = false);
    if (result.success && result.job != null) {
      setState(() {
        _job = result.job!;
        _milestoneController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Failed')),
      );
    }
  }

  Future<void> _toggleMilestone(String milestoneId) async {
    final result = await _trackingService.toggleMilestone(_job['_id'], milestoneId);
    if (!mounted) return;
    if (result.success && result.job != null) {
      setState(() => _job = result.job!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Failed')),
      );
    }
  }

  Future<void> _approveProgress(String updateId, String? milestoneId) async {
    setState(() => _isBusy = true);
    final result = await _trackingService.approveProgress(
      _job['_id'],
      updateId,
      milestoneId: milestoneId,
    );
    if (!mounted) return;
    setState(() => _isBusy = false);
    if (result.success && result.job != null) {
      setState(() => _job = result.job!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Progress update approved and milestone completed!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Failed to approve progress')),
      );
    }
  }

  void _showApproveDialog(String updateId) {
    final incomplete = _milestones.where((m) => m['done'] != true).toList();
    String? selectedMilestoneId =
        incomplete.isNotEmpty ? incomplete.first['_id']?.toString() : null;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Approve Progress Update',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Approving this update confirms the collaborator\'s work and marks the corresponding milestone complete.',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              if (incomplete.isNotEmpty) ...[
                const Text(
                  'Select milestone to complete:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: incomplete.map((m) {
                    final mId = m['_id']?.toString();
                    final isSelected = selectedMilestoneId == mId;
                    return ChoiceChip(
                      label: Text(m['title'] ?? 'Milestone'),
                      selected: isSelected,
                      onSelected: (_) =>
                          setSheetState(() => selectedMilestoneId = mId),
                      selectedColor: AppTheme.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _approveProgress(updateId, selectedMilestoneId);
                },
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Confirm Approval', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFF1DBF73),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentStatus = _job['status'] ?? 'Pending';
    final currentIndex = _statuses.indexOf(currentStatus);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        appBar: AppBar(
          title: Text(_job['title'] ?? 'Progress', overflow: TextOverflow.ellipsis),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _job),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _statuses.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final status = _statuses[index];
                    final isSelected = status == currentStatus;
                    final isPast = index < currentIndex;
                    return ChoiceChip(
                      label: Text(status),
                      selected: isSelected,
                      onSelected: _isBusy ? null : (_) => _updateStatus(status),
                      selectedColor: AppTheme.primary,
                      backgroundColor: isPast ? const Color(0xFFE4F9EE) : Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                        fontSize: 12,
                      ),
                      side: const BorderSide(color: AppTheme.cardBorder),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Text('Milestones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const Spacer(),
                  Text(
                    '${(_progress * 100).round()}% complete',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFF2F2F7),
                  valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              if (_milestones.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('No milestones yet — add one below.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45))),
                )
              else
                ..._milestones.map((m) => Card(
                      child: CheckboxListTile(
                        value: m['done'] == true,
                        onChanged: (_) => _toggleMilestone(m['_id']),
                        title: Text(
                          m['title'] ?? '',
                          style: TextStyle(
                            decoration: m['done'] == true ? TextDecoration.lineThrough : null,
                            color: m['done'] == true ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45) : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        activeColor: AppTheme.primary,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    )),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _milestoneController,
                      decoration: const InputDecoration(
                        hintText: 'Add a milestone...',
                        isDense: true,
                      ),
                      onSubmitted: (_) => _addMilestone(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isBusy ? null : _addMilestone,
                    child: const Icon(Icons.add, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Submitted Progress Updates & Evidence
              _buildProgressUpdatesSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressUpdatesSection() {
    final updates = (_job['progressUpdates'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Submitted Progress Updates',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${updates.length}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (updates.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No progress updates submitted by the collaborator yet.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: updates.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final u = updates[updates.length - 1 - index];
              final updateId = u['_id']?.toString() ?? '';
              final isApproved = u['approved'] == true;
              final desc = u['description'] ?? '';
              final imageUrl = u['imageUrl'];
              final submittedAt = u['submittedAt'] != null
                  ? DateTime.tryParse(u['submittedAt'].toString())
                  : null;
              final dateStr = submittedAt != null
                  ? '${submittedAt.day}/${submittedAt.month}/${submittedAt.year} at ${submittedAt.hour.toString().padLeft(2, '0')}:${submittedAt.minute.toString().padLeft(2, '0')}'
                  : 'Recently';

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isApproved ? const Color(0xFF1DBF73).withValues(alpha: 0.3) : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isApproved ? Icons.check_circle : Icons.check_circle_outline,
                              size: 16,
                              color: const Color(0xFF1DBF73),
                            ),
                            const SizedBox(width: 6),
                            const Text('Progress Evidence', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        if (isApproved)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE4F9EE),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF1DBF73).withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.check_circle, size: 12, color: Color(0xFF1DBF73)),
                                SizedBox(width: 4),
                                Text(
                                  'Approved',
                                  style: TextStyle(
                                    color: Color(0xFF1DBF73),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (!_isCreator)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.schedule, size: 12, color: Colors.amber.shade800),
                                const SizedBox(width: 4),
                                Text(
                                  'Pending Review',
                                  style: TextStyle(
                                    color: Colors.amber.shade900,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(desc, style: const TextStyle(fontSize: 14, height: 1.35)),
                    if (imageUrl != null && imageUrl.toString().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _buildImage(imageUrl.toString()),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        if (_isCreator && !isApproved)
                          ElevatedButton.icon(
                            onPressed: _isBusy ? null : () => _showApproveDialog(updateId),
                            icon: const Icon(Icons.check, size: 15),
                            label: const Text('Approve & Complete Milestone', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1DBF73),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64String = imageUrl.split(',').last;
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      } catch (_) {}
    }
    return Image.network(
      imageUrl,
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}